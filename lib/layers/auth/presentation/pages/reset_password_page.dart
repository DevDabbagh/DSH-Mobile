import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:dsh_mobile/l10n/app_localizations.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/widgets/custom_button.dart';
import 'package:dsh_mobile/app/widgets/custom_text_field.dart';
import 'package:dsh_mobile/layers/auth/presentation/controllers/auth_controller.dart';
import 'package:dsh_mobile/layers/auth/presentation/widgets/auth_scaffold.dart';
import 'package:dsh_mobile/layers/auth/presentation/widgets/password_strength_bar.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _confirmFocus = FocusNode();
  final _isValid = ValueNotifier<bool>(false);
  final _showMismatch = ValueNotifier<bool>(false);

  bool _saving = false;

  @override
  void initState() {
    super.initState();
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
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _confirmFocus.dispose();
    _isValid.dispose();
    _showMismatch.dispose();
    super.dispose();
  }

  void _validateForm() {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final isPasswordValid = password.length >= 8;
    final isConfirmPasswordValid = password == confirmPassword;

    if (isConfirmPasswordValid) _showMismatch.value = false;

    _isValid.value = isPasswordValid && isConfirmPasswordValid;
  }

  void _onResetPassword() {
    FocusScope.of(context).unfocus();
    _saving = true;
    ref
        .read(authControllerProvider.notifier)
        .resetPassword(_passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AsyncLoading;

    ref.listen(authControllerProvider, (previous, next) {
      if (!context.mounted) return;
      if (next is AsyncData && _saving) {
        _saving = false;
        context.go('/password_success');
      } else if (next is AsyncError) {
        _saving = false;
        showAuthError(context, next.error);
      }
    });

    return AuthScaffold(
      backFallback: '/login',
      children: [
        const Center(child: AuthEmblem(icon: Icons.key_outlined)),
        SizedBox(height: 28.h),
        Text(
          'New password',
          textAlign: TextAlign.center,
          style: theme.textTheme.displayMedium?.copyWith(height: 1.2),
        ),
        SizedBox(height: 12.h),
        Text(
          "Choose something strong. You've got this.",
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.60),
            height: 1.5,
          ),
        ),
        SizedBox(height: 32.h),
        AuthCard(
          children: [
            CustomTextField(
              controller: _passwordController,
              hintText: l10n.authPassword,
              prefixIconPath: 'assets/icons/ic_password.svg',
              isPassword: true,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
            ),
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
                if (_isValid.value) _onResetPassword();
              },
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _showMismatch,
              builder: (context, show, child) {
                final mismatch = show &&
                    _confirmPasswordController.text != _passwordController.text;
                if (!mismatch) return SizedBox(height: 20.h);
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.h),
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
            ValueListenableBuilder<bool>(
              valueListenable: _isValid,
              builder: (context, isValid, child) {
                return CustomButton(
                  text: l10n.authResetPassword,
                  type: isValid
                      ? CustomButtonType.gradientFill
                      : CustomButtonType.primaryGrey,
                  isLoading: isLoading,
                  onPressed: isValid ? _onResetPassword : null,
                );
              },
            ),
          ],
        ),
        SizedBox(height: 28.h),
        AuthFooterLink(
          question: 'Back to ',
          action: l10n.authSignIn,
          onTap: () => context.go('/login'),
        ),
      ],
    );
  }
}
