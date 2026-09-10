import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/config/app_dimensions.dart';
import 'package:dsh_mobile/app/widgets/search_scaffold.dart';
import 'package:dsh_mobile/l10n/app_localizations.dart';
import 'package:dsh_mobile/layers/studio/domain/entities/studio_project.dart';
import 'package:dsh_mobile/layers/studio/presentation/controllers/studio_controller.dart';
import 'package:dsh_mobile/layers/studio/presentation/controllers/studio_filter_controller.dart';
import 'package:dsh_mobile/layers/studio/presentation/widgets/studio_filter_sheet.dart';
import 'package:dsh_mobile/layers/studio/presentation/widgets/studio_format_label.dart';
import 'package:dsh_mobile/layers/studio/presentation/widgets/studio_project_card.dart';

/// Searching the studio library — `/studio/search`.
///
/// The twin of `FilmsSearchPage`; see that file for why these live outside
/// the shell and share their filter state with the tab.
class StudioSearchPage extends ConsumerStatefulWidget {
  /// Opens the facet sheet on arrival — see [FilmsSearchPage.openFilter].
  final bool openFilter;

  const StudioSearchPage({super.key, this.openFilter = false});

  @override
  ConsumerState<StudioSearchPage> createState() => _StudioSearchPageState();
}

class _StudioSearchPageState extends ConsumerState<StudioSearchPage> {
  @override
  void initState() {
    super.initState();
    if (widget.openFilter) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) StudioFilterSheet.open(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filter = ref.watch(studioFilterControllerProvider);
    final ctl = ref.read(studioFilterControllerProvider.notifier);
    final all =
        ref.watch(studioListProvider).valueOrNull ?? const <StudioProject>[];

    return SearchScaffold(
      title: l10n.studioTab,
      hint: l10n.searchStudioHint,
      initialQuery: filter.query,
      onSubmitted: ctl.setQuery,
      onFilterTap: () => StudioFilterSheet.open(context),
      activeFilters: filter.activeCount,
      chips: [
        if (filter.format != null)
          SearchChip(
            label: studioFormatLabel(l10n, filter.format!),
            onRemove: () => ctl.setFormat(null),
          ),
        if (filter.status != null)
          SearchChip(
            label: studioStatusLabel(l10n, filter.status!),
            onRemove: () => ctl.setStatus(null),
          ),
      ],
      body: _Results(
        filter: filter,
        matches: filter.apply(all),
        onClear: ctl.clear,
      ),
    );
  }
}

class _Results extends StatelessWidget {
  final StudioFilter filter;
  final List<StudioProject> matches;
  final VoidCallback onClear;

  const _Results({
    required this.filter,
    required this.matches,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final query = filter.query.trim();

    // Nothing typed yet shows the whole library — see FilmsSearchPage for why.
    if (matches.isEmpty) {
      return SearchStatus(
        icon: Icons.search_off,
        message:
            query.isEmpty ? l10n.filterNoResults : l10n.searchNoResults(query),
        action: TextButton(
          onPressed: onClear,
          child: Text(
            l10n.filterClearFilters,
            style: TextStyle(color: AppColors.mainBlue, fontSize: 13.sp),
          ),
        ),
      );
    }

    final cardWidth = MediaQuery.sizeOf(context).width - 40.w;

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.pagePadding.w,
        6.h,
        AppDimensions.pagePadding.w,
        24.h,
      ),
      itemCount: matches.length,
      separatorBuilder: (_, __) => SizedBox(height: 10.h),
      itemBuilder: (context, i) => StudioProjectCard(
        project: matches[i],
        width: cardWidth,
        onTap: () => context.push('/studio/${matches[i].slug}'),
      ),
    );
  }
}
