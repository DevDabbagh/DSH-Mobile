import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:dsh_mobile/l10n/app_localizations.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/widgets/custom_button.dart';
import 'package:dsh_mobile/app/widgets/custom_text_field.dart';
import 'package:dsh_mobile/app/widgets/custom_checkbox.dart';
import 'package:dsh_mobile/layers/auth/domain/auth_repository.dart';
import 'package:dsh_mobile/layers/auth/presentation/controllers/auth_controller.dart';
import 'package:dsh_mobile/layers/auth/presentation/widgets/auth_scaffold.dart';
import 'package:dsh_mobile/layers/auth/presentation/widgets/auth_social_row.dart';
import 'package:dsh_mobile/layers/auth/presentation/widgets/password_strength_bar.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _agreedToTerms = false;
  final _isValid = ValueNotifier<bool>(false);

  /// Set once the user has left the confirm field or typed enough to have an
  /// opinion. Without it, "Passwords don't match" appears on the first
  /// keystroke of a field the user is halfway through filling in — which is
  /// technically true and reads as being nagged.
  final _showMismatch = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    _confirmPasswordController.addListener(_validateForm);
    _confirmFocus.addListener(() {
      if (!_confirmFocus.hasFocus &&
          _confirmPasswordController.text.isNotEmpty) {
        _showMismatch.value = true;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    _isValid.dispose();
    _showMismatch.dispose();
    super.dispose();
  }

  void _validateForm() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    final isNameValid = name.isNotEmpty;
    final isEmailValid = emailRegex.hasMatch(email);
    final isPasswordValid = password.length >= 8;
    final isConfirmPasswordValid = password == confirmPassword;

    if (isConfirmPasswordValid) _showMismatch.value = false;

    _isValid.value = isNameValid &&
        isEmailValid &&
        isPasswordValid &&
        isConfirmPasswordValid &&
        _agreedToTerms;
  }

  /// True from the moment "Create account" is pressed until the OTP screen
  /// has been opened.
  ///
  /// The listener below used to send every success to /otp. That was safe
  /// while this screen could only do one thing; with Google and Apple on it,
  /// opening the browser also completes successfully — and pushed an OTP
  /// screen over the top of it, waiting for a code that was never sent.
  bool _awaitingOtp = false;

  void _onRegister() {
    FocusScope.of(context).unfocus();
    _awaitingOtp = true;
    ref.read(authControllerProvider.notifier).register(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
        );
  }

  void _onProvider(SocialProvider provider) {
    FocusScope.of(context).unfocus();
    _awaitingOtp = false;
    ref.read(authControllerProvider.notifier).signInWithProvider(provider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AsyncLoading;

    // A Google or Apple account needs no code to confirm — the provider has
    // already vouched for the address. Those land as a session instead, so
    // this screen leaves the same way the sign-in screen does.
    ref.listen(currentUserProvider, (previous, next) {
      final arrived = previous?.valueOrNull == null && next.valueOrNull != null;
      if (!arrived || !context.mounted) return;

      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    });

    ref.listen(authControllerProvider, (previous, next) {
      if (!context.mounted) return;
      if (next is AsyncData && _awaitingOtp) {
        _awaitingOtp = false;
        context.push('/otp');
      } else if (next is AsyncError) {
        _awaitingOtp = false;
        showAuthError(context, next.error);
      }
    });

    return AuthScaffold(
      // Six fields and a keyboard is never a short screen. Centring it would
      // make the top jump the moment the keyboard animates in.
      alignTop: true,
      children: [
        SizedBox(height: 8.h),
        AuthHeader(
          title: l10n.authJoinUs,
          subtitle: l10n.authSignInToContinue,
        ),
        SizedBox(height: 26.h),
        AuthCard(
          children: [
            CustomTextField(
              controller: _nameController,
              hintText: l10n.authFullName,
              prefixIcon: Icons.person_outline,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              onFieldSubmitted: (_) => _emailFocus.requestFocus(),
            ),
            SizedBox(height: 14.h),
            CustomTextField(
              controller: _emailController,
              focusNode: _emailFocus,
              hintText: l10n.authEmailAddress,
              prefixIconPath: 'assets/icons/ic_email.svg',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newUsername],
              onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
            ),
            SizedBox(height: 14.h),
            CustomTextField(
              controller: _passwordController,
              focusNode: _passwordFocus,
              hintText: l10n.authPassword,
              prefixIconPath: 'assets/icons/ic_password.svg',
              isPassword: true,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
            ),

            // Immediately under the field it describes, so "at least 8
            // characters" is answered where the question is asked rather
            // than by a rejection after the button is pressed.
            PasswordStrengthBar(controller: _passwordController),

            SizedBox(height: 14.h),
            CustomTextField(
              controller: _confirmPasswordController,
              focusNode: _confirmFocus,
              hintText: l10n.authConfirmPassword,
              prefixIconPath: 'assets/icons/ic_password.svg',
              isPassword: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onFieldSubmitted: (_) {
                _showMismatch.value = true;
                if (_isValid.value) _onRegister();
              },
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _showMismatch,
              builder: (context, show, child) {
                final mismatch = show &&
                    _confirmPasswordController.text != _passwordController.text;
                if (!mismatch) return SizedBox(height: 16.h);
                return Padding(
                  padding: EdgeInsets.only(top: 8.h, bottom: 8.h),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          size: 14.sp, color: AppColors.errorMain),
                      SizedBox(width: 6.w),
                      Text(
                        "Passwords don't match",
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.errorMain),
                      ),
                    ],
                  ),
                );
              },
            ),
            CustomCheckbox(
              value: _agreedToTerms,
              onChanged: (val) {
                setState(() {
                  _agreedToTerms = val ?? false;
                  _validateForm();
                });
              },
              label: RichText(
                text: TextSpan(
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.60),
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: 'I agree to the '),
                    TextSpan(
                      text: 'Terms',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20.h),
            ValueListenableBuilder<bool>(
              valueListenable: _isValid,
              builder: (context, isValid, child) {
                return CustomButton(
                  text: l10n.authCreateAccount,
                  type: isValid
                      ? CustomButtonType.gradientFill
                      : CustomButtonType.primaryGrey,
                  isLoading: isLoading,
                  onPressed: isValid ? _onRegister : null,
                );
              },
            ),
          ],
        ),
        SizedBox(height: 24.h),
        AuthDivider(label: l10n.authOr),
        SizedBox(height: 20.h),
        AuthSocialRow(onProvider: _onProvider, enabled: !isLoading),
        SizedBox(height: 26.h),
        AuthFooterLink(
          question: l10n.authAlreadyHaveAccount,
          action: l10n.authSignIn,
          onTap: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/login');
            }
          },
        ),
        SizedBox(height: 16.h),
      ],
    );
  }
}
