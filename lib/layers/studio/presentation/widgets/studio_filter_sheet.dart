import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dsh_mobile/app/widgets/filter_sheet.dart';
import 'package:dsh_mobile/l10n/app_localizations.dart';
import 'package:dsh_mobile/layers/studio/domain/entities/studio_project.dart';
import 'package:dsh_mobile/layers/studio/presentation/controllers/studio_controller.dart';
import 'package:dsh_mobile/layers/studio/presentation/controllers/studio_filter_controller.dart';
import 'package:dsh_mobile/layers/studio/presentation/widgets/studio_format_label.dart';

/// The studio half of the filter sheet: format and status, the two facets the
/// website filters on.
class StudioFilterSheet extends ConsumerWidget {
  const StudioFilterSheet({super.key});

  static Future<void> open(BuildContext context) => FilterSheet.show(
        context,
        builder: (_) => const StudioFilterSheet(),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final filter = ref.watch(studioFilterControllerProvider);
    final controller = ref.read(studioFilterControllerProvider.notifier);
    final all =
        ref.watch(studioListProvider).valueOrNull ?? const <StudioProject>[];

    return FilterSheet(
      resultCount: filter.apply(all).length,
      hasActiveFilters: filter.isActive,
      onClearAll: controller.clear,
      groups: [
        FilterGroup.of<StudioFormat>(
          label: l10n.filterFormat,
          values: StudioFormat.values,
          labelOf: (f) => studioFormatLabel(l10n, f),
          selected: filter.format,
          onChanged: controller.setFormat,
        ),
        FilterGroup.of<StudioStatus>(
          label: l10n.filterStatus,
          values: StudioStatus.values,
          labelOf: (s) => studioStatusLabel(l10n, s),
          selected: filter.status,
          onChanged: controller.setStatus,
        ),
      ],
    );
  }
}
