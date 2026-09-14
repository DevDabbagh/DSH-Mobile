import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dsh_mobile/l10n/app_localizations.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/config/app_dimensions.dart';
import 'package:dsh_mobile/app/widgets/custom_button.dart';
import 'package:dsh_mobile/app/widgets/custom_text_field.dart';
import 'package:dsh_mobile/app/widgets/social_button.dart';
import 'package:dsh_mobile/layers/auth/domain/auth_repository.dart';
import 'package:dsh_mobile/layers/auth/presentation/controllers/auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _isValid = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _isValid.dispose();
    super.dispose();
  }

  void _validateForm() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    final isEmailValid = emailRegex.hasMatch(email);
    final isPasswordValid = password.isNotEmpty;

    _isValid.value = isEmailValid && isPasswordValid;
  }

  void _onSignIn() {
    FocusScope.of(context).unfocus();
    ref.read(authControllerProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );
  }

  void _onProvider(SocialProvider provider) {
    FocusScope.of(context).unfocus();
    ref.read(authControllerProvider.notifier).signInWithProvider(provider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AsyncLoading;

    // LEAVE WHEN A USER APPEARS, NOT WHEN A CALL FINISHES
    //
    // This used to navigate on any AsyncData from the controller, which was
    // fine while email and password were the only way in. Google and Apple
    // broke it: those calls complete as soon as the BROWSER opens, so the
    // screen would slide away to Home while the user was still picking an
    // account — and if they cancelled, they came back to a signed-out app
    // with no sign-in screen to return to.
    //
    // Watching the user instead covers every route in, including the OAuth
    // session that arrives out of nowhere when the redirect resumes the app.
    ref.listen(currentUserProvider, (previous, next) {
      final arrived = previous?.valueOrNull == null && next.valueOrNull != null;
      if (!arrived || !context.mounted) return;

      // Back where they came from — a film, a donation, the profile tab —
      // rather than always Home. Signing in is something you do in the
      // middle of doing something else.
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    });

    ref.listen(authControllerProvider, (previous, next) {
      if (next is! AsyncError) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: AppColors.cardSurface,
            behavior: SnackBarBehavior.floating,
          ),
        );
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () => context.pop(),
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: AppDimensions.pagePadding.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 20.h),
            Center(
              child: SvgPicture.asset(
                'assets/icons/ic_logo.svg',
                width: 190.w,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              AppLocalizations.of(context)!.authWelcomeBack,
              textAlign: TextAlign.center,
              style: theme.textTheme.displayMedium,
            ),
            SizedBox(height: 4.h),
            Text(
              AppLocalizations.of(context)!.authSignInToContinue,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 30.h),
            CustomTextField(
              controller: _emailController,
              hintText: AppLocalizations.of(context)!.authEmailAddress,
              prefixIconPath: 'assets/icons/ic_email.svg',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            SizedBox(height: 16.h),
            CustomTextField(
              controller: _passwordController,
              hintText: AppLocalizations.of(context)!.authPassword,
              prefixIconPath: 'assets/icons/ic_password.svg',
              isPassword: true,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) {
                if (_isValid.value) _onSignIn();
              },
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: () {
                  context.push('/forgot_password');
                },
                child: Text(
                  AppLocalizations.of(context)!.authForgotPassword,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.mediumGrey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(height: 24.h),
            ValueListenableBuilder<bool>(
              valueListenable: _isValid,
              builder: (context, isValid, child) {
                return CustomButton(
                  text: AppLocalizations.of(context)!.authSignIn,
                  type: isValid
                      ? CustomButtonType.gradientFill
                      : CustomButtonType.primaryGrey,
                  isLoading: isLoading,
                  onPressed: isValid ? _onSignIn : null,
                );
              },
            ),
            SizedBox(height: 24.h),
            Row(
              children: [
                const Expanded(child: Divider(color: AppColors.border)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Text(
                    AppLocalizations.of(context)!.authOr,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: AppColors.textMuted),
                  ),
                ),
                const Expanded(child: Divider(color: AppColors.border)),
              ],
            ),
            SizedBox(height: 32.h),
            SocialButton(
              text: AppLocalizations.of(context)!.authContinueWithGoogle,
              iconPath: 'assets/icons/ic_google.svg',
              onPressed: () => _onProvider(SocialProvider.google),
            ),
            SizedBox(height: 16.h),
            SocialButton(
              text: AppLocalizations.of(context)!.authContinueWithApple,
              iconPath: 'assets/icons/ic_apple_icon.svg',
              onPressed: () => _onProvider(SocialProvider.apple),
            ),
            SizedBox(height: 40.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppLocalizations.of(context)!.authDontHaveAccount,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                GestureDetector(
                  onTap: () => context.push('/register'),
                  child: Text(
                    AppLocalizations.of(context)!.authSignUp,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }
}
