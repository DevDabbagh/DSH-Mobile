/// The shell every auth screen is built in.
///
/// Six screens — sign in, sign up, verify, forgot, reset, done — used to each
/// carry their own Scaffold, their own back button and their own idea of how
/// far down the page starts. They now share this, which is what makes them
/// look like one flow rather than six screens that happen to be next to each
/// other.
///
/// It supplies four things:
///
///   · [AuthBackdrop] behind everything, paused while the keyboard is up.
///   · A field treatment that works on glass — the global input theme fills
///     with solid #363636, which sits on a lit background like a sticker.
///   · A back button that is a control rather than a bare chevron floating in
///     the corner.
///   · Vertical centring when the content is shorter than the screen, and
///     ordinary scrolling when it is not. The old screens padded with fixed
///     `SizedBox`es, which is why the same screen looked balanced on one
///     phone and top-heavy on another.
library;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/config/app_dimensions.dart';
import 'package:dsh_mobile/layers/auth/presentation/widgets/auth_backdrop.dart';

class AuthScaffold extends StatelessWidget {
  final List<Widget> children;

  /// Shows the back control. Off for the screen at the end of a flow, where
  /// going back means going back to a password you have already changed.
  final bool showBack;

  /// Where the back control goes when there is nothing to pop — deep-linking
  /// straight into `/reset_password` is a real route into this flow.
  final String backFallback;

  /// Pins [children] to the top instead of centring them when they are short.
  /// Sign-up needs this: six fields plus a keyboard is never short, and
  /// letting it centre makes the first field jump on the frame the keyboard
  /// opens.
  final bool alignTop;

  const AuthScaffold({
    super.key,
    required this.children,
    this.showBack = true,
    this.backFallback = '/home',
    this.alignTop = false,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: AppColors.black,
      // The backdrop must keep its full height when the keyboard opens, or
      // the glows jump halfway up the screen as it animates in. The scroll
      // view below handles the inset itself.
      resizeToAvoidBottomInset: false,
      body: Theme(
        data: _onGlass(Theme.of(context)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AuthBackdrop(paused: keyboard),
            SafeArea(
              child: Column(
                children: [
                  SizedBox(
                    height: 52.h,
                    child: showBack
                        ? Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Padding(
                              padding: EdgeInsetsDirectional.only(
                                start: AppDimensions.pagePadding.w - 4,
                              ),
                              child: _BackButton(fallback: backFallback),
                            ),
                          )
                        : null,
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        padding: EdgeInsets.only(
                          left: AppDimensions.pagePadding.w,
                          right: AppDimensions.pagePadding.w,
                          bottom: media.viewInsets.bottom + 24.h,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            // Centred in what is VISIBLE, not in the whole
                            // screen. `resizeToAvoidBottomInset` is off, so
                            // without subtracting the keyboard the midpoint
                            // of the form sits underneath it.
                            minHeight: alignTop
                                ? 0.0
                                : (constraints.maxHeight -
                                        media.viewInsets.bottom)
                                    .clamp(0.0, double.infinity),
                          ),
                          child: Column(
                            mainAxisAlignment: alignTop
                                ? MainAxisAlignment.start
                                : MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: children,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The input theme these screens use instead of the app's.
  ///
  /// Translucent white rather than the app's solid grey, a hairline border
  /// that brightens on focus, and a teal focus ring. The point is that a
  /// field looks like a hole cut in the glass with the light showing through,
  /// not like a grey box placed on top of it.
  ThemeData _onGlass(ThemeData base) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14.r),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
    );

    return base.copyWith(
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.mainBlue, width: 1.4),
        ),
        errorBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.error, width: 1.4),
        ),
        hintStyle: base.textTheme.bodyMedium?.copyWith(
          color: Colors.white.withValues(alpha: 0.38),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 17.h),
      ),
      // The caret and the selection handles. Default is the seed purple,
      // which on this background is nearly invisible against the pink glow.
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.mainBlue,
        selectionColor: AppColors.mainBlue.withValues(alpha: 0.30),
        selectionHandleColor: AppColors.mainBlue,
      ),
    );
  }
}

/// A circular glass back control.
class _BackButton extends StatelessWidget {
  final String fallback;

  const _BackButton({required this.fallback});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: MaterialLocalizations.of(context).backButtonTooltip,
      child: InkResponse(
        onTap: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(fallback);
          }
        },
        radius: 24.r,
        child: Container(
          width: 40.r,
          height: 40.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.06),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.arrow_back_ios_new,
            size: 16.sp,
            color: AppColors.smoke,
          ),
        ),
      ),
    );
  }
}

/// The logo, the headline and the line under it.
///
/// Used by the two front doors — sign in and sign up. The screens that are a
/// step inside a flow (verify, forgot, reset, done) show an [AuthEmblem]
/// instead: the logo four times in one flow stops being a mark and becomes
/// furniture, and an icon does the more useful job of saying which step this
/// is.
class AuthHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const AuthHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: SvgPicture.asset(
            'assets/icons/ic_logo.svg',
            width: 168.w,
            fit: BoxFit.contain,
          ),
        ),
        SizedBox(height: 28.h),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.displayMedium?.copyWith(
            height: 1.2,
            letterSpacing: -0.3,
          ),
        ),
        if (subtitle != null) ...[
          SizedBox(height: 10.h),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.60),
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}

/// The panel the form sits in.
///
/// Deliberately not a `BackdropFilter`. There is nothing behind it but smooth
/// gradients, so a blur would cost a full-screen offscreen render every frame
/// and change what you see by almost nothing. Two translucent fills and a
/// hairline get the same read for free.
class AuthCard extends StatelessWidget {
  final List<Widget> children;

  const AuthCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        // Top-lit: brighter at the top edge, fading down. Same reason the
        // backdrop runs light-to-dark — it gives the panel a surface.
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.075),
            Colors.white.withValues(alpha: 0.030),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// A circular emblem in a gradient ring, for the screens with no logo.
class AuthEmblem extends StatelessWidget {
  final IconData icon;

  /// Fills the ring instead of leaving it hollow. The success screen uses it:
  /// a solid gradient disc is a full stop, a hollow ring is a waypoint.
  final bool filled;

  const AuthEmblem({super.key, required this.icon, this.filled = false});

  @override
  Widget build(BuildContext context) {
    final size = 84.r;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.mainPurple.withValues(alpha: 0.35),
            blurRadius: 34,
            spreadRadius: -4,
          ),
        ],
      ),
      padding: EdgeInsets.all(filled ? 0.0 : 1.5.r),
      child: filled
          ? Icon(icon, size: 38.sp, color: AppColors.white)
          : Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                // Opaque, so the ring reads as a ring and not as a gradient
                // disc with a pale icon on it.
                color: Color(0xFF100D12),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 34.sp, color: AppColors.smoke),
            ),
    );
  }
}

/// `── or ──`.
class AuthDivider extends StatelessWidget {
  final String label;

  const AuthDivider({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    // Faded at both ends rather than a flat rule: a hard line across a lit
    // background draws more attention than the word it is separating.
    Widget rule(bool leading) => Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: leading
                    ? AlignmentDirectional.centerStart
                    : AlignmentDirectional.centerEnd,
                end: leading
                    ? AlignmentDirectional.centerEnd
                    : AlignmentDirectional.centerStart,
                colors: [
                  Colors.white.withValues(alpha: 0),
                  Colors.white.withValues(alpha: 0.16),
                ],
              ),
            ),
          ),
        );

    return Row(
      children: [
        rule(true),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          child: Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.42),
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        rule(false),
      ],
    );
  }
}

/// The "Don't have an account? Sign up" line at the foot of a screen.
///
/// A `Row` of two `Text`s was fine in English and wrong everywhere else: it
/// cannot wrap, so the Portuguese and Arabic versions overflowed. This wraps.
class AuthFooterLink extends StatelessWidget {
  final String question;
  final String action;
  final VoidCallback onTap;

  const AuthFooterLink({
    super.key,
    required this.question,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          question,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            // Vertical padding only — horizontal would put a gap between the
            // question and the link. This is here so the tap target clears
            // 44pt without the text moving.
            padding: EdgeInsets.symmetric(vertical: 10.h),
            child: Text(
              action,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The error that comes back from Supabase, shown the same way everywhere.
///
/// A floating SnackBar over a keyboard lands behind it on Android, which is
/// how "wrong password" managed to be invisible on the one screen where it
/// matters most. This is called instead.
void showAuthError(BuildContext context, Object error) {
  final messenger = ScaffoldMessenger.of(context);
  final bottom = MediaQuery.of(context).viewInsets.bottom;

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.errorMain, size: 20.sp),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                error.toString(),
                style: TextStyle(color: AppColors.smoke, fontSize: 13.sp),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1A161C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, bottom + 16.h),
        duration: const Duration(seconds: 4),
      ),
    );
}
