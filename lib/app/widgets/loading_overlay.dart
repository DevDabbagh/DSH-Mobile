import 'package:flutter/material.dart';
import 'package:dsh_mobile/app/config/app_colors.dart';

/// Non-dismissible loading dialog.
class LoadingOverlay {
  LoadingOverlay._();

  static bool _isShowing = false;

  static void show(BuildContext context) {
    if (_isShowing) return;
    _isShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
    );
  }

  static void hide(BuildContext context) {
    if (!_isShowing) return;
    _isShowing = false;
    Navigator.of(context).pop();
  }
}
