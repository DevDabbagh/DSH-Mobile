import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/config/app_dimensions.dart';
import 'package:dsh_mobile/l10n/app_localizations.dart';
import 'package:dsh_mobile/layers/pages/domain/entities/page_section.dart';
import 'package:dsh_mobile/layers/pages/presentation/controllers/page_sections_controller.dart';
import 'package:dsh_mobile/layers/pages/presentation/widgets/page_section_blocks.dart';
import 'package:dsh_mobile/layers/support/domain/entities/donation.dart';
import 'package:dsh_mobile/layers/support/presentation/widgets/donation_card.dart';

/// Support — Figma `2046:9521`.
///
/// THE PAGE IS TWO HALVES, AND THE SPLIT IS DELIBERATE.
///
/// Everything a person could reasonably want to reword — the headline, the
/// promises, the figures, the project cards, the quote, the other ways to
/// help — comes from `page_sections` where page = 'support': the same rows the
/// website renders and the dashboard's Pages editor writes.
///
/// The donation card does not. Amounts, the monthly toggle and the checkout
/// button are behaviour, not copy. An editor should be able to rewrite every
/// word on this screen without being able to break a payment.
///
/// WHAT THE DESIGN ASKS FOR THAT THIS DOES NOT BUILD
///
/// The Figma frame opens with three plan cards — Free, Supporter, Champion —
/// and closes with a loyalty-points panel. Neither exists: there is no plans
/// table, no subscriptions table and no points ledger anywhere in this
/// project, and inventing three prices in a Dart file would put numbers on a
/// payment screen that nothing can honour. So the frame's *shape* is built
/// here — the centred mark, the stacked cards, the pill row, the icon list,
/// the closing panel — and every one of them is filled from something real.
///
/// The frame's centre of gravity moves accordingly: where the design puts
/// plan tiers, this puts the donation card, because that is the thing this
/// screen can actually do.
class SupportPage extends ConsumerWidget {
  /// Set when the donor arrived from a film or studio project. Passed through
  /// to Stripe as metadata so the dashboard can report per-project totals —
  /// exactly what `/support?fundType=…&fundSlug=…&fundTitle=…` does on the web.
  final FundingTarget? target;

  const SupportPage({super.key, this.target});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = ref.watch(pageSectionsListProvider('support'));

    return Scaffold(
      backgroundColor: AppColors.deepBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.white, size: 24.w),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Text(
          'Support',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: sections.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.mediumGrey),
        ),

        // The copy failed to load — but the donation card does not depend on
        // it. Someone who came here to give should still be able to, so the
        // card is shown with a retry above it rather than an error page.
        error: (_, __) => ListView(
          padding: EdgeInsets.only(top: 32.h, bottom: 32.h),
          children: [
            _Retry(
              onRetry: () => ref
                  .read(pageSectionsListProvider('support').notifier)
                  .refresh(),
            ),
            SizedBox(height: 24.h),
            DonationCard(target: target),
          ],
        ),

        data: (list) {
          // The hero is drawn by this screen rather than by the shared block:
          // the design centres it under a logo mark, and the shared `hero` is
          // a left-aligned stack built for About.
          final heroIndex = list.indexWhere((s) => s.kind == 'hero');
          final hero = heroIndex == -1 ? null : list[heroIndex];
          final rest = [
            for (var i = 0; i < list.length; i++)
              if (i != heroIndex) list[i],
          ];

          return RefreshIndicator(
            color: AppColors.mainPurple,
            backgroundColor: AppColors.cardSurface,
            onRefresh: () => ref
                .read(pageSectionsListProvider('support').notifier)
                .refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(bottom: 40.h),
              children: [
                _Masthead(hero: hero),
                SizedBox(height: 26.h),
                DonationCard(target: target),

                // The design's "Where your support goes" list. The three lines
                // are `hero.facts` — the promises the editor already writes on
                // this page — rather than a second set of words somewhere else
                // saying almost the same thing.
                _WhereItGoes(facts: hero?.list('facts') ?? const []),

                for (final s in rest)
                  buildPageSection(s) ?? const SizedBox.shrink(),
              ],
            ),
          );
        },
      ),
    );
  }
}

/* ── masthead ───────────────────────────────────────────────────────── */

/// The mark, the headline and the standfirst, centred — the top third of the
/// Figma frame.
class _Masthead extends StatelessWidget {
  final PageSection? hero;

  const _Masthead({required this.hero});

  @override
  Widget build(BuildContext context) {
    final headline = hero?.str('headline') ?? '';
    final standfirst = hero?.str('standfirst') ?? '';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.pagePadding.w,
        12.h,
        AppDimensions.pagePadding.w,
        0,
      ),
      child: Column(
        children: [
          SvgPicture.asset(
            'assets/icons/ic_logo.svg',
            height: 44.h,
            fit: BoxFit.contain,
          ),
          if (headline.isNotEmpty) ...[
            SizedBox(height: 18.h),
            Text(
              headline,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.white,
                fontSize: 22.sp,
                height: 1.25,
                letterSpacing: -0.4,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          if (standfirst.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Text(
              standfirst,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.lightGrey,
                fontSize: 13.sp,
                height: 20 / 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/* ── where your support goes ────────────────────────────────────────── */

/// The icon list from the design, filled from `hero.facts`.
///
/// The icons are decorative and positional — the first line gets the film
/// glyph, the second the book, the third the globe — because `facts` is a
/// list of sentences and has nowhere to store one. That is the honest
/// trade: an editor changing the wording keeps the icon, and an editor
/// adding a fourth line gets a bullet rather than a wrong picture.
class _WhereItGoes extends StatelessWidget {
  final List<Map<String, dynamic>> facts;

  const _WhereItGoes({required this.facts});

  static const _glyphs = <IconData>[
    Icons.movie_outlined,
    Icons.menu_book_outlined,
    Icons.public_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final lines = [
      for (final f in facts)
        if (f['text'] is String && (f['text'] as String).trim().isNotEmpty)
          f['text'] as String,
    ];

    if (lines.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.pagePadding.w,
        32.h,
        AppDimensions.pagePadding.w,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(AppLocalizations.of(context)!.supportWhereItGoes),
          SizedBox(height: 16.h),
          for (var i = 0; i < lines.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    i < _glyphs.length
                        ? _glyphs[i]
                        : Icons.arrow_forward_outlined,
                    color: AppColors.lightGrey,
                    size: 18.w,
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Text(
                      lines[i],
                      style: TextStyle(
                        color: AppColors.smoke,
                        fontSize: 13.sp,
                        height: 20 / 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Retry extends StatelessWidget {
  final VoidCallback onRetry;
  const _Retry({required this.onRetry});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(
            'Could not load this page.',
            style: TextStyle(color: AppColors.lightGrey, fontSize: 14.sp),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Try again',
              style: TextStyle(color: AppColors.mainPurple, fontSize: 14.sp),
            ),
          ),
        ],
      );
}
