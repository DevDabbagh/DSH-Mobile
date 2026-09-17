import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dsh_mobile/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/widgets/custom_button.dart';
import 'package:dsh_mobile/layers/auth/domain/auth_repository.dart';
import 'package:dsh_mobile/layers/auth/presentation/controllers/auth_controller.dart';
import 'package:dsh_mobile/layers/auth/presentation/widgets/auth_scaffold.dart';

class OtpPage extends ConsumerStatefulWidget {
  const OtpPage({super.key});

  @override
  ConsumerState<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends ConsumerState<OtpPage> {
  final _pinController = TextEditingController();
  final _isValid = ValueNotifier<bool>(false);

  /// Seconds left before "Resend" is offered again.
  ///
  /// A local cooldown on top of Supabase's own rate limit, which is not a
  /// duplicate of it: the server's limit produces an error message, and a
  /// button that can only fail is worse than a button that tells you when it
  /// will work.
  int _cooldown = 0;
  Timer? _timer;
  bool _resending = false;

  @override
  void initState() {
    super.initState();
    _pinController.addListener(_validateForm);
    // A code was sent moments ago by whatever screen sent us here.
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pinController.dispose();
    _isValid.dispose();
    super.dispose();
  }

  void _validateForm() {
    _isValid.value = _pinController.text.length == 6;
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = 45);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _cooldown--);
      if (_cooldown <= 0) timer.cancel();
    });
  }

  void _onVerify() {
    FocusScope.of(context).unfocus();
    ref.read(authControllerProvider.notifier).verifyOtp(_pinController.text);
  }

  Future<void> _onResend() async {
    if (_cooldown > 0 || _resending) return;
    setState(() => _resending = true);

    final error = await ref.read(authControllerProvider.notifier).resendOtp();
    if (!mounted) return;

    setState(() => _resending = false);

    if (error != null) {
      showAuthError(context, error);
      return;
    }

    // The old code stops working the moment a new one is issued, so clearing
    // the field saves the user deleting six digits that can no longer succeed.
    _pinController.clear();
    _startCooldown();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('A new code is on its way.'),
          backgroundColor: const Color(0xFF1A161C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
          ),
          margin: EdgeInsets.all(16.w),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AsyncLoading;

    final pending = ref.watch(pendingVerificationStateProvider);
    // This screen used to name `heba@email.com` — a placeholder from the
    // design that shipped. A verification screen that shows an address the
    // user has never seen is the single most alarming thing an auth flow can
    // do, because the one question it has to answer is "where do I look?".
    final email = pending?.email ?? '';

    ref.listen(authControllerProvider, (previous, next) {
      if (!context.mounted) return;
      if (next is AsyncData) {
        // Where the code came from decides where it leads: a recovery code
        // still has a password to set, a signup confirmation is done.
        if (pending?.purpose == OtpPurpose.recovery) {
          context.push('/reset_password');
        } else {
          context.go('/home');
        }
      } else if (next is AsyncError) {
        // A rejected code leaves six wrong digits in the boxes; clearing them
        // means the next attempt starts by typing rather than by deleting.
        _pinController.clear();
        showAuthError(context, next.error);
      }
    });

    final basePin = PinTheme(
      width: 48.w,
      height: 56.h,
      textStyle: theme.textTheme.displayMedium?.copyWith(
        color: AppColors.white,
        fontSize: 22.sp,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
    );

    return AuthScaffold(
      backFallback: '/login',
      children: [
        const Center(child: AuthEmblem(icon: Icons.mark_email_read_outlined)),
        SizedBox(height: 28.h),
        Text(
          'Enter verification code',
          textAlign: TextAlign.center,
          style: theme.textTheme.displayMedium?.copyWith(height: 1.2),
        ),
        SizedBox(height: 12.h),
        Text.rich(
          TextSpan(
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.60),
              height: 1.5,
            ),
            children: [
              const TextSpan(text: 'We sent a 6-digit code to\n'),
              TextSpan(
                text: email,
                style: TextStyle(
                  color: AppColors.smoke,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 32.h),
        Center(
          child: Directionality(
            // Digits are entered left to right in every language. In Arabic
            // the row would otherwise fill from the right, so the first digit
            // typed landed in the last box.
            textDirection: TextDirection.ltr,
            child: Pinput(
              length: 6,
              controller: _pinController,
              autofocus: true,
              defaultPinTheme: basePin,
              focusedPinTheme: basePin.copyWith(
                decoration: basePin.decoration?.copyWith(
                  border: Border.all(color: AppColors.mainBlue, width: 1.4),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.mainBlue.withValues(alpha: 0.22),
                      blurRadius: 14,
                      spreadRadius: -2,
                    ),
                  ],
                ),
              ),
              submittedPinTheme: basePin.copyWith(
                decoration: basePin.decoration?.copyWith(
                  color: Colors.white.withValues(alpha: 0.09),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.22)),
                ),
              ),
              onCompleted: (_) => _onVerify(),
            ),
          ),
        ),
        SizedBox(height: 14.h),
        Text(
          'Code expires in 15 minutes',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.38),
          ),
        ),
        SizedBox(height: 28.h),
        ValueListenableBuilder<bool>(
          valueListenable: _isValid,
          builder: (context, isValid, child) {
            return CustomButton(
              text: l10n.authVerify,
              type: isValid
                  ? CustomButtonType.gradientFill
                  : CustomButtonType.primaryGrey,
              isLoading: isLoading,
              onPressed: isValid ? _onVerify : null,
            );
          },
        ),
        SizedBox(height: 24.h),
        if (_cooldown > 0)
          Text(
            'You can ask for a new code in ${_cooldown}s',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.38),
            ),
          )
        else if (_resending)
          Center(
            child: SizedBox(
              width: 18.w,
              height: 18.w,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.mainBlue,
              ),
            ),
          )
        else
          AuthFooterLink(
            question: l10n.authDidntReceiveCode,
            action: l10n.authResend,
            onTap: _onResend,
          ),
        SizedBox(height: 12.h),
        Center(
          child: GestureDetector(
            onTap: () {
              // Leaving means abandoning this code; the next screen issues
              // its own. Without the clear, going back to sign-up and using a
              // different address still verified against the old one.
              ref.read(pendingVerificationStateProvider.notifier).clear();
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/login');
              }
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10.h),
              child: Text(
                'Try a different email',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.38),
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white.withValues(alpha: 0.20),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
