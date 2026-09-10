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
import 'package:dsh_mobile/app/widgets/custom_checkbox.dart';
import 'package:dsh_mobile/app/widgets/social_button.dart';
import 'package:dsh_mobile/layers/auth/presentation/controllers/auth_controller.dart';

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

  bool _agreedToTerms = false;
  final _isValid = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    _confirmPasswordController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _isValid.dispose();
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

    _isValid.value = isNameValid &&
        isEmailValid &&
        isPasswordValid &&
        isConfirmPasswordValid &&
        _agreedToTerms;
  }

  void _onRegister() {
    FocusScope.of(context).unfocus();
    ref.read(authControllerProvider.notifier).register(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AsyncLoading;

    ref.listen(authControllerProvider, (previous, next) {
      if (next is AsyncData) {
        context.push('/otp'); // Go to verification after register
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 10.h),
            Center(
              child: SvgPicture.asset(
                'assets/icons/ic_logo.svg',
                width: 180.w,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              AppLocalizations.of(context)!.authJoinUs,
              textAlign: TextAlign.center,
              style: theme.textTheme.displayMedium,
            ),
            SizedBox(height: 8.h),
            Text(
              AppLocalizations.of(context)!.authSignInToContinue,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 32.h),
            CustomTextField(
              controller: _nameController,
              hintText: AppLocalizations.of(context)!.authFullName,
              prefixIcon: Icons.person_outline,
              textInputAction: TextInputAction.next,
            ),
            SizedBox(height: 16.h),
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
              textInputAction: TextInputAction.next,
            ),
            SizedBox(height: 16.h),
            CustomTextField(
              controller: _confirmPasswordController,
              hintText: AppLocalizations.of(context)!.authConfirmPassword,
              prefixIconPath: 'assets/icons/ic_password.svg',
              isPassword: true,
              textInputAction: TextInputAction.done,
            ),
            SizedBox(height: 16.h),
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
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  children: [
                    const TextSpan(text: 'I agree to the '),
                    TextSpan(
                      text: 'Terms',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24.h),
            ValueListenableBuilder<bool>(
              valueListenable: _isValid,
              builder: (context, isValid, child) {
                return CustomButton(
                  text: AppLocalizations.of(context)!.authCreateAccount,
                  type: isValid
                      ? CustomButtonType.gradientFill
                      : CustomButtonType.primaryGrey,
                  isLoading: isLoading,
                  onPressed: isValid ? _onRegister : null,
                );
              },
            ),
            SizedBox(height: 32.h),
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
              onPressed: () {},
            ),
            SizedBox(height: 16.h),
            SocialButton(
              text: AppLocalizations.of(context)!.authContinueWithApple,
              iconPath: 'assets/icons/ic_apple_icon.svg',
              onPressed: () {},
            ),
            SizedBox(height: 30.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppLocalizations.of(context)!.authAlreadyHaveAccount,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                GestureDetector(
                  onTap: () => context.pop(),
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
