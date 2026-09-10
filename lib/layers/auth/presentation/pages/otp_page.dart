import 'package:flutter/material.dart';
import 'package:dsh_mobile/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/config/app_dimensions.dart';
import 'package:dsh_mobile/app/widgets/custom_button.dart';
import 'package:dsh_mobile/layers/auth/domain/auth_repository.dart';
import 'package:dsh_mobile/layers/auth/presentation/controllers/auth_controller.dart';

class OtpPage extends ConsumerStatefulWidget {
  const OtpPage({super.key});

  @override
  ConsumerState<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends ConsumerState<OtpPage> {
  final _pinController = TextEditingController();
  final _isValid = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _pinController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _pinController.dispose();
    _isValid.dispose();
    super.dispose();
  }

  void _validateForm() {
    _isValid.value = _pinController.text.length == 6;
  }

  void _onVerify() {
    FocusScope.of(context).unfocus();
    ref.read(authControllerProvider.notifier).verifyOtp(_pinController.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AsyncLoading;

    ref.listen(authControllerProvider, (previous, next) {
      if (next is AsyncData) {
        // Where the code came from decides where it leads: a recovery code
        // still has a password to set, a signup confirmation is done.
        final pending = ref.read(pendingVerificationStateProvider);
        if (pending?.purpose == OtpPurpose.recovery) {
          context.push('/reset_password');
        } else {
          context.go('/home');
        }
      } else if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error.toString())),
        );
      }
    });

    final defaultPinTheme = PinTheme(
      width: 50.w,
      height: 60.h,
      textStyle: theme.textTheme.displayMedium?.copyWith(
        color: AppColors.white,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        border: Border.all(color: AppColors.mainPurple, width: 1.5),
      ),
    );

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
            SizedBox(height: 40.h),

            // Checkmark shield icon
            Center(
              child: SvgPicture.asset(
                'assets/icons/ic_verification_icon.svg',
                width: 64.w,
                fit: BoxFit.contain,
              ),
            ),

            SizedBox(height: 24.h),

            Text(
              'Enter verification code',
              textAlign: TextAlign.center,
              style: theme.textTheme.displayMedium,
            ),
            SizedBox(height: 12.h),
            Text(
              'We sent a 6-digit code to\nheba@email.com',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Code expires in 15 minutes',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            SizedBox(height: 40.h),

            Center(
              child: Pinput(
                length: 6,
                controller: _pinController,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: focusedPinTheme,
                submittedPinTheme: defaultPinTheme,
                onCompleted: (_) => _onVerify(),
              ),
            ),
            SizedBox(height: 40.h),

            ValueListenableBuilder<bool>(
              valueListenable: _isValid,
              builder: (context, isValid, child) {
                return CustomButton(
                  text: AppLocalizations.of(context)!.authVerify,
                  type: isValid
                      ? CustomButtonType.gradientFill
                      : CustomButtonType.primaryGrey,
                  isLoading: isLoading,
                  onPressed: isValid ? _onVerify : null,
                );
              },
            ),

            SizedBox(height: 32.h),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Didn't receive it? ",
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                GestureDetector(
                  onTap: () {},
                  child: Text(
                    AppLocalizations.of(context)!.authResend,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Center(
              child: GestureDetector(
                onTap: () => context.pop(),
                child: Text(
                  'Try a different email',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }
}
