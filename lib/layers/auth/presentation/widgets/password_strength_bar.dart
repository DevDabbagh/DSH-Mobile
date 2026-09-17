/// How good the password being typed is, shown while it is being typed.
///
/// It lived inline on the reset screen and nowhere else, which meant sign-up
/// — the screen where a password is actually chosen — gave no feedback at all
/// until the button refused to light up. That is the wrong way round.
///
/// WHAT IT MEASURES, AND WHAT IT DOES NOT
///
/// Four cheap signals: length, mixed case, a digit, a symbol. This is not an
/// entropy estimate and it is not zxcvbn — `Password1!` scores full marks
/// here and would be cracked in seconds. It is a nudge, and it is honest
/// about being one: nothing below it is blocked except the eight-character
/// minimum the server also enforces.
library;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';

class PasswordStrengthBar extends StatelessWidget {
  final TextEditingController controller;

  const PasswordStrengthBar({super.key, required this.controller});

  /// 0 (nothing typed) to 4.
  static int score(String password) {
    if (password.isEmpty) return 0;

    var points = 0;
    if (password.length >= 8) points++;
    if (password.length >= 12) points++;
    if (RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[A-Z]').hasMatch(password)) {
      points++;
    }
    if (RegExp(r'[0-9]').hasMatch(password) &&
        RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      points++;
    }

    // Under the minimum it can never read as anything but weak, whatever else
    // is in it — otherwise `Aa1!` shows two bars for a password the form will
    // reject.
    if (password.length < 8) return 1;
    return points.clamp(1, 4);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final n = score(value.text);
        if (n == 0) return SizedBox(height: 8.h);

        final tooShort = value.text.length < 8;
        final (label, color) = switch (n) {
          1 => (
              tooShort ? 'At least 8 characters' : 'Weak',
              AppColors.errorMain
            ),
          2 => ('Fair', AppColors.warningMain),
          3 => ('Good', AppColors.mainBlue),
          _ => ('Strong', AppColors.successMain),
        };

        return Padding(
          padding: EdgeInsets.only(top: 10.h, bottom: 2.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: List.generate(4, (i) {
                  final lit = i < n;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      height: 3.h,
                      margin:
                          EdgeInsetsDirectional.only(end: i == 3 ? 0.0 : 4.w),
                      decoration: BoxDecoration(
                        color:
                            lit ? color : Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  );
                }),
              ),
              SizedBox(height: 7.h),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 11.sp,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
