import 'package:flutter/material.dart';
import 'package:dsh_mobile/app/config/app_colors.dart';

class Loader extends StatelessWidget {
  final Color? color;

  const Loader({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: color ?? AppColors.primary,
      ),
    );
  }
}
