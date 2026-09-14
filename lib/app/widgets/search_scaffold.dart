import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/config/app_dimensions.dart';

/// How much has to be typed before a search runs.
///
/// One or two letters match most of the catalogue, so the list churns under
/// the reader's thumb on every keystroke and settles on nothing useful. Three
/// is where a query starts to mean something. The keyboard's search key
/// overrides it — someone who deliberately pressed search has said they meant
/// those two letters.
const int kSearchMinChars = 3;

/// The chrome every search screen shares: the field, the clear button, and
/// the row of chips for whatever is currently narrowing the results.
///
/// WHY IT IS A SCREEN AND NOT A BAR ON THE TAB
///
/// Searching is a mode, not a control. It wants the keyboard, the whole
/// height for results, and no tab bar underneath stealing the bottom of the
/// list — so these screens are declared outside the shell and cover it.
///
/// [SearchScaffold] draws the frame; the caller supplies what to search and
/// how to draw a result.
class SearchScaffold extends StatefulWidget {
  /// "Films", "Studio", "Academy" — or the platform-wide screen's own title.
  final String title;

  final String hint;

  /// The query as the owner currently holds it. Seeded into the field once,
  /// so arriving from a tab that already had a query keeps it.
  final String initialQuery;

  /// Fired only once [kSearchMinChars] is reached, or the query is cleared,
  /// or the keyboard's search key is pressed.
  final ValueChanged<String> onSubmitted;

  /// Opens the facet sheet. Null on a screen with nothing to filter — the
  /// icon is then absent rather than present and inert.
  final VoidCallback? onFilterTap;

  final int activeFilters;

  /// One per set facet. Tapping the × clears that facet only.
  final List<SearchChip> chips;

  /// Everything below the chips. Results, or the empty/idle state — the owner
  /// decides which, because only it knows whether a query has been run.
  final Widget body;

  /// Whether typing runs the search, or only the keyboard's search key does.
  ///
  /// True on the section screens: they are already showing one list, and
  /// narrowing it live under the reader's thumb is the whole appeal.
  ///
  /// False on the platform-wide screen. That one is a form — a query AND a
  /// set of sections to look in — and it leaves for a results page when it is
  /// submitted. Running it on the third keystroke would throw the reader onto
  /// the results before they had finished choosing where to look.
  final bool searchAsYouType;

  const SearchScaffold({
    super.key,
    required this.title,
    required this.hint,
    required this.initialQuery,
    required this.onSubmitted,
    required this.chips,
    required this.body,
    this.onFilterTap,
    this.activeFilters = 0,
    this.searchAsYouType = true,
  });

  @override
  State<SearchScaffold> createState() => _SearchScaffoldState();
}

class _SearchScaffoldState extends State<SearchScaffold> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialQuery);

  /// Autofocus on the field itself would open the keyboard before the push
  /// transition finished, which jumps the layout mid-animation. This asks for
  /// focus once the first frame is on screen instead.
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// The threshold, in one place.
  ///
  /// Clearing the field always reports through, even though '' is under the
  /// minimum: otherwise deleting a query would leave the last results on
  /// screen with an empty box above them.
  void _onChanged(String value) {
    if (!widget.searchAsYouType) return;

    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.length >= kSearchMinChars) {
      widget.onSubmitted(trimmed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBackground,
      appBar: AppBar(
        backgroundColor: AppColors.deepBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.white, size: 22.w),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            color: AppColors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        // Centred, unlike the tabs. A search screen is a mode you entered on
        // purpose and will leave again; centring the title with a back arrow
        // beside it says "this is a stop", where a left-aligned title says
        // "this is where you live".
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppDimensions.pagePadding.w,
              4.h,
              AppDimensions.pagePadding.w,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44.h,
                    padding: EdgeInsetsDirectional.only(start: 14.w, end: 6.w),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      // Fully rounded, as the search frame draws it.
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.smoke.withValues(alpha: 0.10),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          color: AppColors.mediumGrey,
                          size: 18.w,
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          // The app's `InputDecorationTheme` is built for the
                          // sign-in forms: a filled box with a gradient
                          // focused border. Inherited here it drew a pink
                          // outlined rectangle floating inside the pill —
                          // setting every border to `none` on the decoration
                          // suppresses the border but not the rest of it, so
                          // the theme is removed for this one field instead of
                          // overridden field by field.
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              inputDecorationTheme: const InputDecorationTheme(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                filled: false,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            child: TextField(
                              controller: _controller,
                              focusNode: _focus,
                              onChanged: _onChanged,
                              // The keyboard's search key ignores the minimum:
                              // pressing it is someone saying they meant those
                              // two letters.
                              onSubmitted: (v) => widget.onSubmitted(v.trim()),
                              textInputAction: TextInputAction.search,
                              cursorColor: AppColors.mainBlue,
                              style: TextStyle(
                                color: AppColors.smoke,
                                fontSize: 14.sp,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                // ALL of them, not just `border`.
                                //
                                // `border` is only the fallback. The app theme
                                // sets a focused border with the brand
                                // gradient colours on it, and that one wins the
                                // moment the field has focus — which, on this
                                // screen, is immediately. The result was a
                                // pink-outlined box floating inside the pill,
                                // which is what made this look like a form
                                // rather than a search.
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                                filled: false,
                                fillColor: Colors.transparent,
                                contentPadding: EdgeInsets.zero,
                                hintText: widget.hint,
                                hintStyle: TextStyle(
                                  color: AppColors.mediumGrey,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Only once there is something to clear. A permanent
                        // × on an empty field is a button that does nothing.
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _controller,
                          builder: (_, value, __) => value.text.isEmpty
                              ? SizedBox(width: 8.w)
                              : GestureDetector(
                                  onTap: () {
                                    _controller.clear();
                                    widget.onSubmitted('');
                                    _focus.requestFocus();
                                  },
                                  behavior: HitTestBehavior.opaque,
                                  child: Padding(
                                    padding: EdgeInsets.all(6.w),
                                    child: Icon(
                                      Icons.close,
                                      color: AppColors.mediumGrey,
                                      size: 16.w,
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (widget.onFilterTap != null) ...[
                  SizedBox(width: 10.w),
                  _FilterButton(
                    count: widget.activeFilters,
                    onTap: widget.onFilterTap!,
                  ),
                ],
              ],
            ),
          ),

          // What is currently narrowing the list, and how to undo each piece
          // of it. Without these the only way to see which facets are set is
          // to reopen the sheet.
          if (widget.chips.isNotEmpty)
            SizedBox(
              height: 46.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.fromLTRB(
                  AppDimensions.pagePadding.w,
                  12.h,
                  AppDimensions.pagePadding.w,
                  0,
                ),
                itemCount: widget.chips.length,
                separatorBuilder: (_, __) => SizedBox(width: 8.w),
                itemBuilder: (_, i) => _Chip(chip: widget.chips[i]),
              ),
            ),

          SizedBox(height: 6.h),
          Expanded(child: widget.body),
        ],
      ),
    );
  }
}

/// One active facet, and how to remove it.
class SearchChip {
  final String label;
  final VoidCallback onRemove;

  /// The section's own colour, when it has one. Null falls back to plain
  /// white, which is what a facet like "Documentary" gets — it belongs to a
  /// filter, not to a place.
  final Color? accent;

  const SearchChip({
    required this.label,
    required this.onRemove,
    this.accent,
  });
}

class _Chip extends StatelessWidget {
  final SearchChip chip;

  const _Chip({required this.chip});

  @override
  Widget build(BuildContext context) {
    final accent = chip.accent ?? AppColors.smoke;

    // Tinted rather than filled. A row of solid white pills under a dark
    // search field reads as five buttons demanding to be pressed; these are a
    // statement of what is already on, so they sit back — the section's colour
    // at low alpha, its own outline, and the text in that colour rather than
    // knocked out of it. It also means the six sections stay recognisable
    // here by the same colour they carry in the Browse grid.
    return Container(
      padding: EdgeInsetsDirectional.only(start: 13.w, end: 5.w),
      height: 32.h,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: accent.withValues(alpha: 0.55),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            chip.label,
            style: TextStyle(
              color: accent,
              fontSize: 12.sp,
              height: 1,
              fontWeight: FontWeight.w600,
            ),
          ),
          GestureDetector(
            onTap: chip.onRemove,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.all(6.w),
              child: Icon(
                Icons.close,
                color: accent.withValues(alpha: 0.85),
                size: 13.w,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _FilterButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final on = count > 0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 44.h,
        width: 44.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? AppColors.smoke : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color:
                on ? AppColors.smoke : AppColors.smoke.withValues(alpha: 0.10),
            width: 0.8,
          ),
        ),
        child: Icon(
          Icons.tune,
          color: on ? AppColors.deepBackground : AppColors.lightGrey,
          size: 18.w,
        ),
      ),
    );
  }
}

/// The state a search screen is in before anything has been typed, and the
/// state it is in when nothing matched. Two messages, one widget, because
/// they occupy the same space and must not jump between each other.
class SearchStatus extends StatelessWidget {
  final IconData icon;
  final String message;
  final Widget? action;

  const SearchStatus({
    super.key,
    required this.icon,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.mediumGrey, size: 30.w),
            SizedBox(height: 14.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.lightGrey,
                fontSize: 13.sp,
                height: 1.5,
              ),
            ),
            if (action != null) ...[SizedBox(height: 4.h), action!],
          ],
        ),
      ),
    );
  }
}
