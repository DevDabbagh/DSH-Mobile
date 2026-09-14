import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/config/app_dimensions.dart';
import 'package:dsh_mobile/app/widgets/app_network_image.dart';
import 'package:dsh_mobile/layers/auth/domain/entities/app_user.dart';
import 'package:dsh_mobile/layers/auth/presentation/controllers/auth_controller.dart';
import 'package:dsh_mobile/layers/home/presentation/widgets/home_chrome.dart';
import 'package:dsh_mobile/layers/notifications/presentation/controllers/notifications_controller.dart';

/// Logo, notifications, account.
///
/// Not a `page_sections` row: this is chrome. An editor who could hide it
/// would remove the only way into the notification inbox and the profile.
class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final unread = ref.watch(unreadCountProvider).valueOrNull ?? 0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.pagePadding.w,
        vertical: 8.h,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SvgPicture.asset(
            'assets/icons/ic_logo.svg',
            width: 80.w,
            fit: BoxFit.contain,
          ),
          Row(
            children: [
              // The bell was an icon with no gesture on it. It opens the
              // inbox now, and carries the unread count.
              GestureDetector(
                onTap: () => context.push('/notifications'),
                behavior: HitTestBehavior.opaque,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      color: AppColors.white,
                      size: 24.w,
                    ),
                    if (unread > 0)
                      PositionedDirectional(
                        end: -2.w,
                        top: -2.h,
                        child: Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.primaryGradient,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(width: 16.w),
              // A real account or nothing. A stock face here read as "you are
              // signed in as someone" to every guest who opened the app.
              _HeaderAvatar(user: user),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderAvatar extends StatelessWidget {
  final AppUser? user;

  const _HeaderAvatar({required this.user});

  @override
  Widget build(BuildContext context) {
    final signedIn = user != null;

    return GestureDetector(
      // Always the Profile tab, signed in or not.
      //
      // A guest used to be sent straight to `/login`, which skipped the one
      // screen built to explain what an account is for — Profile already has
      // a guest state, with the sign-in prompt inside it. Jumping past it made
      // the avatar a login button wearing a person's face, and it put a
      // full-screen form in front of anyone who tapped it out of curiosity.
      //
      // It also broke the tab bar: `/login` is outside the shell, so the bar
      // vanished and there was no way back except the system gesture.
      onTap: () => goToRoute(context, '/profile'),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 32.w,
        height: 32.w,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface,
          border: Border.all(color: AppColors.white.withValues(alpha: 0.1)),
        ),
        child: !signedIn
            ? Icon(
                Icons.person_outline,
                color: AppColors.textMuted,
                size: 18.w,
              )
            : (user!.avatarUrl?.isNotEmpty ?? false)
                ? AppNetworkImage(
                    url: user!.avatarUrl!,
                    fit: BoxFit.cover,
                    fallback: _Initials(user: user!),
                    // An avatar is ~36px. It is also on every screen.
                    thumb: true,
                  )
                : _Initials(user: user!),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  final AppUser user;

  const _Initials({required this.user});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: Center(
        child: Text(
          user.initials,
          style: TextStyle(
            color: AppColors.white,
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// What Home shows before the layout arrives.
class HomeShimmer extends StatelessWidget {
  const HomeShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[900]!,
      highlightColor: Colors.grey[800]!,
      child: SingleChildScrollView(
        // Scrollable even though there is nothing to scroll to.
        //
        // A `RefreshIndicator` only fires when its child reports an overscroll,
        // and `NeverScrollableScrollPhysics` never does. So the shimmer was
        // telling people to pull down to refresh while being the one widget on
        // the screen that could not be pulled — which is the exact moment
        // refreshing matters most.
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppDimensions.pagePadding.w,
                vertical: 12.h,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(width: 80.w, height: 24.h, color: Colors.white),
                  Row(
                    children: [
                      _Circle(size: 24.w),
                      SizedBox(width: 16.w),
                      _Circle(size: 32.w),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              height: 380.h,
              width: double.infinity,
              color: Colors.white,
            ),
            SizedBox(height: 24.h),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppDimensions.pagePadding.w,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  4,
                  (_) => Column(
                    children: [
                      _Circle(size: 56.w),
                      SizedBox(height: 8.h),
                      Container(width: 40.w, height: 10.h, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 32.h),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppDimensions.pagePadding.w,
              ),
              child: Container(
                width: 120.w,
                height: 20.h,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              height: 220.h,
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.pagePadding.w,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                separatorBuilder: (_, __) => SizedBox(width: 12.w),
                itemBuilder: (_, __) => Container(
                  width: 140.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6.r),
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

class _Circle extends StatelessWidget {
  final double size;

  const _Circle({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
    );
  }
}
