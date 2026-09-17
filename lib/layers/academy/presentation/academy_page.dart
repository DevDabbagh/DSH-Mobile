import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/config/app_dimensions.dart';
import 'package:dsh_mobile/app/core/errors/failures.dart';
import 'package:dsh_mobile/app/supabase/section_header.dart';
import 'package:dsh_mobile/app/widgets/detail_section.dart';
import 'package:dsh_mobile/app/widgets/drifting_mosaic.dart';
import 'package:dsh_mobile/app/widgets/empty_state_widget.dart';
import 'package:dsh_mobile/app/widgets/error_retry_widget.dart';
import 'package:dsh_mobile/app/widgets/section_app_bar.dart';
import 'package:dsh_mobile/app/widgets/segmented_headline.dart';
import 'package:dsh_mobile/l10n/app_localizations.dart';
import 'package:dsh_mobile/layers/academy/domain/entities/academy_program.dart';
import 'package:dsh_mobile/layers/academy/presentation/controllers/academy_controller.dart';
import 'package:dsh_mobile/layers/academy/presentation/controllers/academy_filter_controller.dart';
import 'package:dsh_mobile/layers/academy/presentation/widgets/academy_atoms.dart';
import 'package:dsh_mobile/layers/academy/presentation/widgets/academy_featured_card.dart';
import 'package:dsh_mobile/layers/academy/presentation/widgets/academy_list_card.dart';
import 'package:dsh_mobile/layers/academy/presentation/widgets/academy_newsletter_card.dart';
import 'package:dsh_mobile/layers/academy/presentation/widgets/academy_program_sheet.dart';
import 'package:dsh_mobile/layers/academy/presentation/widgets/academy_ways_in.dart';

/// The Academy tab — Figma `2266:806`.
///
/// Replaces a fifteen-line placeholder. The data layer has been live since
/// the programmes repository was written; this is the screen that was missing.
///
/// The order of the sections is the frame's: hero, "Five ways in", the
/// featured programme, search, the two filter strips, the library, the
/// newsletter, the footer mark.
///
/// WHAT IT SHARES WITH FILMS AND STUDIO, AND WHY
///
/// The hero is [SectionSliverAppBar] over a [DriftingMosaic] at the same 400 /
/// 330 / two-rows geometry, and the section eyebrows are
/// `DetailSection.studioLabel()`. The frame draws its own versions of both,
/// close enough to the other two tabs that building them separately would
/// have produced a third slightly-different wall and a third slightly-
/// different eyebrow — which is the failure mode this app has already been
/// through once.
///
/// WHERE IT FOLLOWS THE WEBSITE INSTEAD
///
/// The filtering is `AcademyListing.tsx` line for line: `programs[0]` is
/// featured and excluded from the grid, the type tabs are built from the types
/// actually present rather than a fixed list, and tapping the active chip
/// clears it. See [AcademyFilter] for the one place mobile goes further.
class AcademyPage extends ConsumerWidget {
  const AcademyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final programsAsync = ref.watch(academyProgramsProvider);

    return Scaffold(
      backgroundColor: AppColors.deepBackground,
      body: programsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.mainBlue),
        ),
        error: (error, _) => SafeArea(
          child: ErrorRetryWidget(
            message: error is Failure ? error.message : l10n.academySubtitle,
            onRetry: () => ref.read(academyProgramsProvider.notifier).refresh(),
          ),
        ),
        data: (programs) => RefreshIndicator(
          color: AppColors.mainBlue,
          backgroundColor: AppColors.cardSurface,
          onRefresh: () => ref.read(academyProgramsProvider.notifier).refresh(),
          child: _AcademyContent(programs: programs),
        ),
      ),
    );
  }
}

class _AcademyContent extends ConsumerStatefulWidget {
  final List<AcademyProgram> programs;

  const _AcademyContent({required this.programs});

  @override
  ConsumerState<_AcademyContent> createState() => _AcademyContentState();
}

class _AcademyContentState extends ConsumerState<_AcademyContent> {
  /// So the circles in "Five ways in" and the "Explore courses" button can
  /// bring the library into view after setting a filter. Without it they
  /// change something the reader cannot see — the list is a screen and a half
  /// further down.
  final _libraryKey = GlobalKey();

  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _jumpToLibrary() {
    final ctx = _libraryKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      // Clears the pinned app bar, which would otherwise sit over the row
      // this is trying to reveal.
      alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      alignment: 0.08,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final programs = widget.programs;

    if (programs.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 160.h),
          EmptyStateWidget(
            icon: Icons.school_outlined,
            title: l10n.academyTitle,
            subtitle: l10n.academySubtitle,
          ),
        ],
      );
    }

    final filter = ref.watch(academyFilterControllerProvider);
    final filterCtl = ref.read(academyFilterControllerProvider.notifier);

    // The website's rule: the first programme leads and is not repeated in
    // the list below it.
    final featured = programs.first;
    final rest = programs.where((p) => p.id != featured.id).toList();

    final matches = filter.apply(rest);

    // Built from what exists, not from a fixed list — a tab for a kind of
    // programme nobody has published yet is a filter that can only ever
    // return nothing.
    //
    // Deduplicated BY LABEL, not by type, and that is not fussiness:
    // `academyTypeLabel` maps both `toolkit` and `resource` to "Toolkits",
    // following the website's own TYPE_LABELS. A library holding one of each
    // would otherwise draw the chip twice, and the second one would look
    // broken because tapping it filters to a different set.
    //
    // First type wins, so the chip filters to whichever kind the library
    // actually leads with. This is a narrower answer than the label promises
    // — it is worth revisiting whether `resource` should exist separately at
    // all, since nothing in either surface treats it differently.
    final presentTypes = <AcademyType>[];
    final seenLabels = <String>{};
    for (final type in AcademyType.values) {
      if (!rest.any((p) => p.type == type)) continue;
      if (!seenLabels.add(academyTypeLabel(type))) continue;
      presentTypes.add(type);
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SectionSliverAppBar(
          title: l10n.academyTab,
          // The same wall as Films and Studio.
          expandedHeight: 400.h,
          background: const _Hero(),

          // NO FILTER ICON HERE, AND THAT IS THE FRAME'S DECISION
          //
          // Films and Studio put search and filters in the bar because those
          // tabs carry neither in the page. This frame does the opposite: a
          // search field and two chip strips sit above the library, where the
          // reader is already looking. A filter icon in the bar would open a
          // sheet offering the same two facets as the chips a thumb-width
          // below it — two controls for one job, and the one further from the
          // list wins the reader's attention.
          //
          // `onFilter` is nullable for exactly this, so the icon is absent
          // rather than present and inert.
          //
          // The magnifier stays, but it goes to the platform-wide search
          // rather than a scoped one: the in-page field already searches the
          // Academy, so the only thing left for this icon to add is reach
          // across films, studio work and courses at once.
          onSearch: () => context.push('/search'),
        ),

        SliverToBoxAdapter(
          child: AcademyWaysIn(
            eyebrow: 'Five ways in',
            headline: 'From a single toolkit to a six-month mentorship.',
            note: 'Free by principle.',
            selected: filter.type,
            onSelect: (type) {
              // Tapping the selected one clears it, like the chips below and
              // like the website's price filter.
              filterCtl.setType(filter.type == type ? null : type);
              _jumpToLibrary();
            },
          ),
        ),

        SliverToBoxAdapter(
          child: DetailSection(
            labelStyle: DetailSection.studioLabel(),
            label: 'Featured',
            child: AcademyFeaturedCard(
              program: featured,
              // There is no `/academy/:slug` route — see AcademyProgramSheet
              // for why this opens a sheet and what to change when there is.
              onTap: () => AcademyProgramSheet.show(context, featured),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            key: _libraryKey,
            padding: EdgeInsets.only(top: 32.h),
            child: _SearchField(
              controller: _searchController,
              onChanged: filterCtl.setQuery,
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: _TypeStrip(
            types: presentTypes,
            selected: filter.type,
            onSelect: filterCtl.setType,
          ),
        ),

        SliverToBoxAdapter(
          child: _PriceStrip(
            selected: filter.price,
            onSelect: filterCtl.setPrice,
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppDimensions.pagePadding.w,
              12.h,
              AppDimensions.pagePadding.w,
              14.h,
            ),
            child: Text(
              'Education that names power and builds capacity.',
              style: TextStyle(
                color: AppColors.smoke,
                fontSize: 15.sp,
                height: 1.4,
                letterSpacing: -0.3,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        SliverPadding(
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.pagePadding.w,
          ),
          sliver: matches.isEmpty
              ? SliverToBoxAdapter(child: _NoMatches(onClear: filterCtl.clear))
              : SliverList.separated(
                  itemCount: matches.length,
                  separatorBuilder: (_, __) => SizedBox(height: 10.h),
                  itemBuilder: (context, i) => AcademyListCard(
                    program: matches[i],
                    onTap: () => AcademyProgramSheet.show(context, matches[i]),
                  ),
                ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppDimensions.pagePadding.w,
              36.h,
              AppDimensions.pagePadding.w,
              0,
            ),
            child: const AcademyNewsletterCard(),
          ),
        ),

        const SliverToBoxAdapter(child: _Footer()),
        // Clears the floating tab bar.
        SliverToBoxAdapter(child: SizedBox(height: 110.h)),
      ],
    );
  }
}

/// The mosaic and the headline, behind [SectionSliverAppBar].
class _Hero extends ConsumerWidget {
  const _Hero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final header = ref
            .watch(sectionHeaderProvider(SectionHeaderKey.academy))
            .valueOrNull ??
        const SectionHeader();

    final images = header.resolve(ref.watch(headerImagePoolsProvider));

    return SizedBox(
      height: 330.h,
      child: Stack(
        children: [
          Positioned.fill(
            child: DriftingMosaic(
              imageUrls: images,
              height: 330.h,
              rowCount: 2,
              grayscale: true,
              opacity: 1,
              // Course stills are as varied in brightness as the film
              // posters, so this takes the longer fade for the same reason
              // Films does — see DriftingMosaic.kDeepScrim.
              scrimGradient: DriftingMosaic.kDeepScrim,
            ),
          ),
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: 22.h,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppDimensions.pagePadding.w,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SegmentedHeadline(
                    segments: _headlineSegments(header),
                    maxLines: 3,
                    minFontSize: 15,
                    style: TextStyle(
                      color: AppColors.smoke,
                      // 29, not the 27 Films and Studio use — the frame sets
                      // this headline larger because it runs to three lines
                      // and carries the section on its own, with no paragraph
                      // under it.
                      fontSize: 29.sp,
                      height: 1.21,
                      letterSpacing: -0.7,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Row(
                    children: [
                      const _GlassAction(label: 'Explore courses'),
                      SizedBox(width: 8.w),
                      const _GlassAction(label: 'Get started'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Knowledge is **power**. Education is **resistance**." — two highlighted
/// runs, which is one more than Films has and the reason the headline is three
/// lines rather than two.
///
/// The dashboard's three-part header (`titleNormal` / `titleColored` /
/// `titleAfter`) can only express one highlight, so an editor who writes their
/// own gets that shape; the app's own copy keeps both.
List<({String text, bool highlight})> _headlineSegments(SectionHeader header) {
  if (header.hasTitle) {
    return [
      if (header.titleNormal.isNotEmpty)
        (text: '${header.titleNormal} ', highlight: false),
      if (header.titleColored.isNotEmpty)
        (text: header.titleColored, highlight: true),
      if (header.titleAfter.isNotEmpty)
        (text: ' ${header.titleAfter}', highlight: false),
    ];
  }

  return [
    (text: 'Knowledge is ', highlight: false),
    (text: 'power.', highlight: true),
    (text: ' Education is ', highlight: false),
    (text: 'resistance.', highlight: true),
  ];
}

class _GlassAction extends StatelessWidget {
  final String label;

  const _GlassAction({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34.h,
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.darkBackground.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(3.r),
        border: Border.all(
          color: AppColors.smoke.withValues(alpha: 0.20),
          width: 0.6,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.smoke,
          fontSize: 12.sp,
          height: 1.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppDimensions.pagePadding.w),
      child: SizedBox(
        height: 38.h,
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: TextStyle(color: AppColors.smoke, fontSize: 13.sp),
          cursorColor: AppColors.mainBlue,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search courses, instructors…',
            hintStyle:
                TextStyle(color: AppColors.academyMuted, fontSize: 13.sp),
            prefixIcon: Icon(
              Icons.search,
              size: 15.w,
              color: AppColors.academyMuted,
            ),
            prefixIconConstraints: BoxConstraints(minWidth: 36.w),
            filled: true,
            fillColor: AppColors.smoke.withValues(alpha: 0.05),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 10.h),
            border: _border(),
            enabledBorder: _border(),
            focusedBorder: _border(color: AppColors.mainBlue, width: 1.2),
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _border({Color? color, double width = 0.6}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(6.r),
        borderSide: BorderSide(
          color: color ?? AppColors.smoke.withValues(alpha: 0.10),
          width: width,
        ),
      );
}

class _TypeStrip extends StatelessWidget {
  final List<AcademyType> types;
  final AcademyType? selected;
  final ValueChanged<AcademyType?> onSelect;

  const _TypeStrip({
    required this.types,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 12.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: AppDimensions.pagePadding.w),
        child: Row(
          children: [
            AcademyFilterChip(
              label: 'View All',
              selected: selected == null,
              onTap: () => onSelect(null),
            ),
            for (final type in types) ...[
              SizedBox(width: 6.w),
              AcademyFilterChip(
                label: academyTypeLabel(type),
                selected: selected == type,
                onTap: () => onSelect(selected == type ? null : type),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PriceStrip extends StatelessWidget {
  final AcademyPrice? selected;
  final ValueChanged<AcademyPrice?> onSelect;

  const _PriceStrip({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 6.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: AppDimensions.pagePadding.w),
        child: Row(
          children: [
            AcademyFilterChip(
              label: 'All prices',
              selected: selected == null,
              dense: true,
              onTap: () => onSelect(null),
            ),
            SizedBox(width: 6.w),
            AcademyFilterChip(
              label: 'Free',
              selected: selected == AcademyPrice.free,
              dense: true,
              // The lime, so the word carries the same meaning here as it
              // does on every card.
              idleColor: AppColors.academyFree.withValues(alpha: 0.55),
              onTap: () => onSelect(
                selected == AcademyPrice.free ? null : AcademyPrice.free,
              ),
            ),
            SizedBox(width: 6.w),
            AcademyFilterChip(
              label: 'Paid',
              selected: selected == AcademyPrice.paid,
              dense: true,
              onTap: () => onSelect(
                selected == AcademyPrice.paid ? null : AcademyPrice.paid,
              ),
            ),
            SizedBox(width: 6.w),
            AcademyFilterChip(
              label: 'Scholarship',
              selected: selected == AcademyPrice.scholarship,
              dense: true,
              onTap: () => onSelect(
                selected == AcademyPrice.scholarship
                    ? null
                    : AcademyPrice.scholarship,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A filter that matches nothing is a normal outcome, not an error — say so,
/// and carry the way out with it.
class _NoMatches extends StatelessWidget {
  final VoidCallback onClear;

  const _NoMatches({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 40.h),
      child: Column(
        children: [
          Text(
            'Nothing here yet under those filters.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.lightGrey,
              fontSize: 13.sp,
              height: 1.5,
            ),
          ),
          SizedBox(height: 12.h),
          GestureDetector(
            onTap: onClear,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
              child: Text(
                'Clear filters',
                style: TextStyle(
                  color: AppColors.mainBlue,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The mark and the line under it — Figma 2266:1243.
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 40.h),
      child: Column(
        children: [
          SvgPicture.asset(
            'assets/icons/ic_logo.svg',
            width: 54.w,
            fit: BoxFit.contain,
          ),
          SizedBox(height: 10.h),
          Text(
            // The year is read rather than typed: a hardcoded one is wrong
            // every January and nobody notices until someone screenshots it.
            '© ${DateTime.now().year} DSH Academy. All rights reserved.',
            style: TextStyle(
              color: AppColors.smoke.withValues(alpha: 0.25),
              fontSize: 10.sp,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
