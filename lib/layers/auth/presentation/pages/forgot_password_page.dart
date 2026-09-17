import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:dsh_mobile/l10n/app_localizations.dart';

import 'package:dsh_mobile/app/widgets/custom_button.dart';
import 'package:dsh_mobile/app/widgets/custom_text_field.dart';
import 'package:dsh_mobile/layers/auth/presentation/controllers/auth_controller.dart';
import 'package:dsh_mobile/layers/auth/presentation/widgets/auth_scaffold.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _isValid = ValueNotifier<bool>(false);

  /// True only between pressing "Send code" and arriving at the OTP screen.
  ///
  /// The controller's state is shared across the whole flow, so without this
  /// an [AsyncData] that belongs to some other call would push a second OTP
  /// screen on top of this one — the same trap the sign-up screen hit.
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _isValid.dispose();
    super.dispose();
  }

  void _validateForm() {
    final email = _emailController.text.trim();
    final emailValid =
        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
    _isValid.value = emailValid;
  }

  void _onSendCode() {
    FocusScope.of(context).unfocus();
    _sending = true;
    ref
        .read(authControllerProvider.notifier)
        .sendPasswordResetEmail(_emailController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AsyncLoading;

    ref.listen(authControllerProvider, (previous, next) {
      if (!context.mounted) return;
      if (next is AsyncData && _sending) {
        _sending = false;
        context.push('/otp');
      } else if (next is AsyncError) {
        _sending = false;
        showAuthError(context, next.error);
      }
    });

    return AuthScaffold(
      backFallback: '/login',
      children: [
        const Center(child: AuthEmblem(icon: Icons.lock_reset_rounded)),
        SizedBox(height: 28.h),
        Text(
          'Reset your password',
          textAlign: TextAlign.center,
          style: theme.textTheme.displayMedium?.copyWith(height: 1.2),
        ),
        SizedBox(height: 12.h),
        Text(
          "Enter the email linked to your account and we'll send you a "
          'verification code.',
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
              controller: _emailController,
              hintText: l10n.authEmailAddress,
              prefixIconPath: 'assets/icons/ic_email.svg',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.username],
              onFieldSubmitted: (_) {
                if (_isValid.value) _onSendCode();
              },
            ),
            SizedBox(height: 20.h),
            ValueListenableBuilder<bool>(
              valueListenable: _isValid,
              builder: (context, isValid, child) {
                return CustomButton(
                  text: 'Send code',
                  type: isValid
                      ? CustomButtonType.gradientFill
                      : CustomButtonType.primaryGrey,
                  isLoading: isLoading,
                  onPressed: isValid ? _onSendCode : null,
                );
              },
            ),
          ],
        ),
        SizedBox(height: 28.h),
        AuthFooterLink(
          question: l10n.authRememberedPassword,
          action: l10n.authSignIn,
          onTap: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/login');
            }
          },
        ),
      ],
    );
  }
}
