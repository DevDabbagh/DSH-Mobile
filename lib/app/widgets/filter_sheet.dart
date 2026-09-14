import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/config/app_dimensions.dart';
import 'package:dsh_mobile/l10n/app_localizations.dart';

/// One choice inside a facet: what it says, whether it is on, what tapping it
/// does. No type parameter — by the time it reaches the sheet the enum has
/// been resolved to a label and a callback.
class FilterOption {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const FilterOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });
}

/// One facet in a filter sheet — "Stage", "Format", "Status".
///
/// NOT GENERIC, AND THAT IS THE WHOLE POINT
///
/// The first version was `FilterGroup<T>` holding `String Function(T) labelOf`,
/// and the sheet took a `List<FilterGroup>`. Dart lets a
/// `FilterGroup<FilmForm>` be *stored* in that list — class type parameters
/// are covariant — but the function inside it is still
/// `String Function(FilmForm)`, and calling it through
/// `String Function(dynamic)` throws at runtime:
///
///   type '(FilmForm) => String' is not a subtype of type '(dynamic) => String'
///
/// It compiled cleanly and crashed the moment the sheet opened. The fix is not
/// a cast — it is to resolve the type at the call site, where it is known, and
/// hand the sheet plain strings and callbacks. [FilterGroup.of] does that, so
/// the call sites still read in terms of their own enums.
class FilterGroup {
  final String label;
  final List<FilterOption> options;

  /// True when this facet is on "All".
  final bool isAny;

  /// Clears just this facet.
  final VoidCallback onClearGroup;

  const FilterGroup({
    required this.label,
    required this.options,
    required this.isAny,
    required this.onClearGroup,
  });

  /// Builds a facet from an enum, with the type known here rather than
  /// smuggled into the sheet.
  ///
  /// `null` means "all" throughout, which is why [selected] and the argument
  /// to [onChanged] are nullable rather than the group carrying a separate
  /// flag.
  static FilterGroup of<T extends Object>({
    required String label,
    required List<T> values,
    required String Function(T) labelOf,
    required T? selected,
    required ValueChanged<T?> onChanged,
  }) {
    return FilterGroup(
      label: label,
      isAny: selected == null,
      onClearGroup: () => onChanged(null),
      options: [
        for (final value in values)
          FilterOption(
            label: labelOf(value),
            selected: selected == value,
            // Tapping the selected chip clears it. Every filter in this app
            // can be undone by pressing the thing that set it.
            onTap: () => onChanged(selected == value ? null : value),
          ),
      ],
    );
  }
}

/// The bottom sheet behind the filter button.
///
/// WHY A SHEET AND NOT A ROW OF CHIPS
///
/// The website has room to lay every facet out along the top of the listing;
/// a phone does not. Films filter on stage AND form, studio on format AND
/// status — four to six chips per facet. Flattened into a horizontal strip
/// they become a scroll nobody scrolls, and the second facet is never
/// discovered at all.
///
/// The sheet is also where "how many will this leave" can be answered
/// honestly: the button at the bottom counts the result of the choices
/// currently made, live, so nobody applies a filter to find out it emptied
/// the page.
///
/// STATE LIVES OUTSIDE THIS WIDGET
///
/// Each group writes straight through to the caller's controller as it is
/// tapped, rather than collecting a draft and committing on "Apply". That is
/// what lets the count under the button be true, and it means dismissing the
/// sheet by swiping — which is how a sheet is usually closed — cannot
/// silently discard what someone just chose.
class FilterSheet extends StatelessWidget {
  final List<FilterGroup> groups;

  /// How many items the current choices leave. Shown on the close button.
  final int resultCount;

  final VoidCallback onClearAll;

  /// True when anything is set — enables "Clear all".
  final bool hasActiveFilters;

  const FilterSheet({
    super.key,
    required this.groups,
    required this.resultCount,
    required this.onClearAll,
    required this.hasActiveFilters,
  });

  /// Opens the sheet. Returns when it is dismissed; there is nothing to
  /// return, because every choice was already applied as it was made.
  static Future<void> show(
    BuildContext context, {
    required WidgetBuilder builder,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      // The root navigator, so the sheet covers the floating tab bar
      // instead of sliding up underneath it — the bar is drawn by the
      // shell, which owns the branch navigator a modal would otherwise
      // mount inside.
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: builder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.deepBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(14.r)),
        border: Border(
          top: BorderSide(color: AppColors.smoke.withValues(alpha: 0.10)),
        ),
      ),
      padding: EdgeInsets.only(
        // Clears the keyboard when the sheet is opened with the search field
        // still focused, and the home indicator when it is not.
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            16.h,
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10.h),
            Center(
              child: Container(
                width: 36.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.mediumGrey,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppDimensions.pagePadding.w,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.filterTitle,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  // Present but inert when nothing is set, rather than absent:
                  // a control that appears and disappears between openings
                  // reads as a glitch.
                  GestureDetector(
                    onTap: hasActiveFilters ? onClearAll : null,
                    behavior: HitTestBehavior.opaque,
                    child: Text(
                      l10n.filterClearAll,
                      style: TextStyle(
                        color: hasActiveFilters
                            ? AppColors.mainBlue
                            : AppColors.mediumGrey,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 18.h),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final group in groups) _Group(group: group),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10.h),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppDimensions.pagePadding.w,
              ),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  decoration: BoxDecoration(
                    color: AppColors.smoke,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    l10n.filterShowResults(resultCount),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.deepBackground,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  final FilterGroup group;

  const _Group({required this.group});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.pagePadding.w,
        0,
        AppDimensions.pagePadding.w,
        22.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.label.toUpperCase(),
            style: TextStyle(
              color: AppColors.mediumGrey,
              fontSize: 10.sp,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              // "All" is a chip like any other rather than a reset button off
              // to one side, because it is a choice about this facet and not
              // about the sheet.
              FilterChipTile(
                label: l10n.filterAny,
                selected: group.isAny,
                onTap: group.onClearGroup,
              ),
              for (final option in group.options)
                FilterChipTile(
                  label: option.label,
                  selected: option.selected,
                  onTap: option.onTap,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The chip used inside the sheet, and on the tabs' own chip rows, so the two
/// cannot drift into looking like different controls.
class FilterChipTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const FilterChipTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.smoke : Colors.transparent,
          borderRadius: BorderRadius.circular(3.r),
          border: Border.all(
            color: selected
                ? AppColors.smoke
                : AppColors.smoke.withValues(alpha: 0.14),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.deepBackground : AppColors.lightGrey,
            fontSize: 12.sp,
            height: 1.2,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
