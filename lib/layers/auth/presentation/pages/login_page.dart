import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:dsh_mobile/l10n/app_localizations.dart';

import 'package:dsh_mobile/app/widgets/custom_button.dart';
import 'package:dsh_mobile/app/widgets/custom_text_field.dart';
import 'package:dsh_mobile/layers/auth/domain/auth_repository.dart';
import 'package:dsh_mobile/layers/auth/presentation/controllers/auth_controller.dart';
import 'package:dsh_mobile/layers/auth/presentation/widgets/auth_scaffold.dart';
import 'package:dsh_mobile/layers/auth/presentation/widgets/auth_social_row.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
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
    _passwordFocus.dispose();
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
    final l10n = AppLocalizations.of(context)!;
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
      if (next is! AsyncError || !context.mounted) return;
      showAuthError(context, next.error);
    });

    return AuthScaffold(
      children: [
        AuthHeader(
          title: l10n.authWelcomeBack,
          subtitle: l10n.authSignInToContinue,
        ),
        SizedBox(height: 28.h),
        AuthCard(
          children: [
            CustomTextField(
              controller: _emailController,
              hintText: l10n.authEmailAddress,
              prefixIconPath: 'assets/icons/ic_email.svg',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
            ),
            SizedBox(height: 14.h),
            CustomTextField(
              controller: _passwordController,
              focusNode: _passwordFocus,
              hintText: l10n.authPassword,
              prefixIconPath: 'assets/icons/ic_password.svg',
              isPassword: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) {
                if (_isValid.value) _onSignIn();
              },
            ),
            SizedBox(height: 4.h),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: () => context.push('/forgot_password'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  minimumSize: Size(0, 36.h),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  l10n.authForgotPassword,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.60),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            ValueListenableBuilder<bool>(
              valueListenable: _isValid,
              builder: (context, isValid, child) {
                return CustomButton(
                  text: l10n.authSignIn,
                  type: isValid
                      ? CustomButtonType.gradientFill
                      : CustomButtonType.primaryGrey,
                  isLoading: isLoading,
                  onPressed: isValid ? _onSignIn : null,
                );
              },
            ),
          ],
        ),
        SizedBox(height: 24.h),
        AuthDivider(label: l10n.authOr),
        SizedBox(height: 20.h),
        AuthSocialRow(onProvider: _onProvider, enabled: !isLoading),
        SizedBox(height: 28.h),
        AuthFooterLink(
          question: l10n.authDontHaveAccount,
          action: l10n.authSignUp,
          onTap: () => context.push('/register'),
        ),
      ],
    );
  }
}
