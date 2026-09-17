import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:dsh_mobile/l10n/app_localizations.dart';

import 'package:dsh_mobile/app/widgets/custom_button.dart';
import 'package:dsh_mobile/layers/auth/presentation/widgets/auth_scaffold.dart';

class PasswordSuccessPage extends StatelessWidget {
  const PasswordSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return AuthScaffold(
      // Back from here means back to a password that no longer exists.
      showBack: false,
      children: [
        const Center(
            child: AuthEmblem(icon: Icons.check_rounded, filled: true)),
        SizedBox(height: 32.h),
        Text(
          'Password reset\nsuccessful',
          textAlign: TextAlign.center,
          style: theme.textTheme.displayMedium?.copyWith(height: 1.25),
        ),
        SizedBox(height: 14.h),
        Text(
          'You can now sign in with your new password.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.60),
            height: 1.5,
          ),
        ),
        SizedBox(height: 40.h),
        CustomButton(
          text: l10n.authSignIn,
          type: CustomButtonType.gradientFill,
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }
}
