import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/config/app_dimensions.dart';

/// The title row on a section tab — Films, Studio, Academy — as a pinned
/// app bar over the hero.
///
/// WHAT THIS FIXES
///
/// The title used to be a `PositionedDirectional` inside the hero `Stack`, so
/// it scrolled away with the mosaic. The search icon beside it had no gesture
/// on it at all, and the filters were glass chips further down the same
/// image — which meant that by the time a reader was looking at the list, all
/// three controls were off the top of the screen.
///
/// The first attempt at fixing that put a full search field in a pinned bar
/// above the list. It worked and it looked wrong: a fat rounded input parked
/// permanently in the middle of the page, competing with the content it was
/// meant to serve.
///
/// This is the version that keeps both properties. `SliverAppBar` gives the
/// behaviour for free: `flexibleSpace` holds the hero, so at rest the bar is
/// invisible and the title floats on the imagery exactly as the design draws
/// it; as the hero collapses, `backgroundColor` takes over and the title and
/// its two icons stay put at the top. Nothing new is invented — the icons
/// simply became real buttons and stopped scrolling away.
class SectionSliverAppBar extends StatelessWidget {
  final String title;

  /// The hero. Drawn behind the bar and scrolled out from under it.
  final Widget background;

  /// Total height with the hero showing. The bar collapses to `kToolbarHeight`.
  final double expandedHeight;

  final VoidCallback onSearch;

  /// Omitted on a tab with nothing to filter. The icon is then absent rather
  /// than present and inert.
  final VoidCallback? onFilter;

  /// How many facets are set — draws a dot on the filter icon. A filtered
  /// list that looks unfiltered is the most common way to conclude that
  /// content has gone missing.
  final int activeFilters;

  const SectionSliverAppBar({
    super.key,
    required this.title,
    required this.background,
    required this.expandedHeight,
    required this.onSearch,
    this.onFilter,
    this.activeFilters = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: expandedHeight,
      // Opaque once collapsed, so the list slides under a solid bar rather
      // than a smear of poster art.
      backgroundColor: AppColors.deepBackground,
      // Material 3 tints a scrolled app bar towards the seed colour. On a
      // near-black surface that reads as a purple wash appearing out of
      // nowhere the moment you scroll.
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      // These are tab roots. A back arrow here would suggest somewhere to go
      // back to, and there is not.
      automaticallyImplyLeading: false,
      // Explicitly left, because the app's `appBarTheme` sets
      // `centerTitle: true` for the auth screens and every bar inherits it.
      // A tab title is a label for the screen you are already on, and it
      // belongs at the start of the line with the headline underneath it —
      // the search screens centre theirs, and that difference is what tells
      // the two apart at a glance.
      centerTitle: false,
      titleSpacing: AppDimensions.pagePadding.w,
      title: Text(
        title,
        style: TextStyle(
          color: AppColors.white,
          fontSize: 18.sp,
          height: 1.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        _BarIcon(icon: Icons.search, onTap: onSearch),
        if (onFilter != null)
          _BarIcon(
            icon: Icons.tune,
            onTap: onFilter!,
            badge: activeFilters,
          ),
        SizedBox(width: AppDimensions.pagePadding.w - 8.w),
      ],
      flexibleSpace: FlexibleSpaceBar(
        // The hero is a fixed composition with a headline positioned in it;
        // parallax would slide that headline out of the frame it was placed
        // in. `pin` keeps it whole while it is clipped away from the top.
        collapseMode: CollapseMode.pin,
        // ClipRect, and it is not decoration.
        //
        // `FlexibleSpaceBar` does not clip its background. A hero whose
        // content is taller than `expandedHeight` therefore paints straight
        // over the list below it — and because the app bar repaints on every
        // frame of the mosaic animation while the list does not, the overflow
        // is drawn again at each new scroll offset without the old one being
        // cleared. That is the smearing on the Studio tab: its hero carries a
        // headline, a paragraph and two buttons, and ran past the bottom.
        //
        // RepaintBoundary for the other half of the same problem: the mosaic
        // animates forever, so without one the whole viewport is marked dirty
        // every frame.
        background: ClipRect(
          child: RepaintBoundary(child: background),
        ),
      ),
    );
  }
}

class _BarIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int badge;

  const _BarIcon({
    required this.icon,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: AppColors.white, size: 20.w),
            if (badge > 0)
              PositionedDirectional(
                end: -3.w,
                top: -3.h,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  constraints: BoxConstraints(minWidth: 13.w),
                  height: 13.w,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                  child: Text(
                    '$badge',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 8.sp,
                      height: 1,
                      fontWeight: FontWeight.w700,
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
