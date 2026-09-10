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
import 'package:dsh_mobile/layers/auth/presentation/controllers/auth_controller.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _isValid = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validateForm);
    _confirmPasswordController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _isValid.dispose();
    super.dispose();
  }

  void _validateForm() {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final isPasswordValid = password.length >= 8;
    final isConfirmPasswordValid = password == confirmPassword;

    _isValid.value = isPasswordValid && isConfirmPasswordValid;
  }

  void _onResetPassword() {
    FocusScope.of(context).unfocus();
    ref
        .read(authControllerProvider.notifier)
        .resetPassword(_passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AsyncLoading;

    ref.listen(authControllerProvider, (previous, next) {
      if (next is AsyncData) {
        context.go('/password_success');
      } else if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error.toString())),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: AppDimensions.pagePadding.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 40.h),
            Center(
              child: SvgPicture.asset(
                'assets/icons/ic_logo.svg',
                width: 180.w,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: 40.h),

            Text(
              'New password',
              textAlign: TextAlign.center,
              style: theme.textTheme.displayMedium,
            ),
            SizedBox(height: 8.h),
            Text(
              'Choose something strong. You\'ve got this.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 40.h),

            CustomTextField(
              controller: _passwordController,
              hintText: 'Str0ng!Pass#2026',
              prefixIconPath: 'assets/icons/ic_password.svg',
              isPassword: true,
              textInputAction: TextInputAction.next,
            ),
            SizedBox(height: 8.h),

            // Password strength indicator
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _passwordController,
              builder: (context, value, child) {
                final length = value.text.length;
                if (length == 0) return const SizedBox.shrink();

                final isStrong = length >= 8;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 3.h,
                      margin: EdgeInsetsDirectional.only(bottom: 8.h),
                      decoration: BoxDecoration(
                        gradient: isStrong ? AppColors.primaryGradient : null,
                        color: isStrong ? null : AppColors.error,
                        borderRadius: BorderRadius.circular(1.5.r),
                      ),
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Text(
                        isStrong ? 'Strong' : 'Weak',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              isStrong ? AppColors.mainBlue : AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            SizedBox(height: 16.h),

            CustomTextField(
              controller: _confirmPasswordController,
              hintText: 'Str0ng!Pass#2026',
              prefixIconPath: 'assets/icons/ic_password.svg',
              isPassword: true,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) {
                if (_isValid.value) _onResetPassword();
              },
            ),
            SizedBox(height: 32.h),

            ValueListenableBuilder<bool>(
              valueListenable: _isValid,
              builder: (context, isValid, child) {
                return CustomButton(
                  text: AppLocalizations.of(context)!.authResetPassword,
                  type: isValid
                      ? CustomButtonType.gradientFill
                      : CustomButtonType.primaryGrey,
                  isLoading: isLoading,
                  onPressed: isValid ? _onResetPassword : null,
                );
              },
            ),

            SizedBox(height: 40.h),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Back to ",
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                GestureDetector(
                  onTap: () => context.go('/login'),
                  child: Text(
                    AppLocalizations.of(context)!.authSignIn,
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
