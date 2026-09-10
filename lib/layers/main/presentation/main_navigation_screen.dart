import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/config/app_dimensions.dart';
import 'package:dsh_mobile/l10n/app_localizations.dart';

class MainNavigationScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainNavigationScreen({
    super.key,
    required this.navigationShell,
  });

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.brandBlack,
      body: Stack(
        children: [
          navigationShell,
          PositionedDirectional(
            start: AppDimensions.pagePadding.w,
            end: AppDimensions.pagePadding.w,
            bottom: 24.h,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40.r),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: 70.h,
                  decoration: BoxDecoration(
                    color: Colors.black
                        .withValues(alpha: 0.6), // Dark black, transparent
                    borderRadius: BorderRadius.circular(40.r),
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _NavItem(
                        asset: 'assets/icons/ic_nav_home.svg',
                        label: l10n.homeTab,
                        isActive: navigationShell.currentIndex == 0,
                        onTap: () => _onTap(0),
                      ),
                      _NavItem(
                        asset: 'assets/icons/ic_nav_films.svg',
                        label: l10n.filmsTab,
                        isActive: navigationShell.currentIndex == 1,
                        onTap: () => _onTap(1),
                      ),
                      _NavItem(
                        asset: 'assets/icons/ic_nav_academy.svg',
                        label: l10n.academyTab,
                        isActive: navigationShell.currentIndex == 2,
                        onTap: () => _onTap(2),
                      ),
                      _NavItem(
                        asset: 'assets/icons/ic_nav_studio.svg',
                        label: l10n.studioTab,
                        isActive: navigationShell.currentIndex == 3,
                        onTap: () => _onTap(3),
                      ),
                      _NavItem(
                        asset: 'assets/icons/ic_nav_profile.svg',
                        label: l10n.profileTab,
                        isActive: navigationShell.currentIndex == 4,
                        onTap: () => _onTap(4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One tab in the bar.
///
/// The design draws every tab with the same stroked icon and separates the
/// states by *opacity*, not by a second filled shape: the selected tab is
/// solid white inside its capsule, the rest sit at 25%. The exported SVGs
/// carried that 25% baked into `stroke-opacity`, which would have pinned all
/// five to the inactive look — it was stripped from the files so the tint
/// below is the single thing deciding the state.
class _NavItem extends StatelessWidget {
  final String asset;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.asset,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: isActive
            ? EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h)
            : EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.mediumGrey.withValues(alpha: 0.8)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              asset,
              width: 22.w,
              height: 22.w,
              colorFilter: ColorFilter.mode(
                AppColors.white.withValues(alpha: isActive ? 1 : 0.25),
                BlendMode.srcIn,
              ),
            ),
            if (isActive) ...[
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ]
          ],
        ),
      ),
    );
  }
}
