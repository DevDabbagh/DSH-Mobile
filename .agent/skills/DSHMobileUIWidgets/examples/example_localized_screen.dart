import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dsh_mobile/l10n/app_localizations.dart';
import 'package:dsh_mobile/app/config/app_dimensions.dart';
import 'package:dsh_mobile/app/config/app_colors.dart';

class ExampleLocalizedScreen extends StatelessWidget {
  const ExampleLocalizedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. ALWAYS retrieve localizations via context
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        // 2. NEVER hardcode "Title"
        title: Text(l10n.welcomeTitle), 
      ),
      body: Padding(
        // 3. ALWAYS use directional padding and screen util extensions
        padding: EdgeInsetsDirectional.symmetric(horizontal: AppDimensions.pagePadding.w),
        child: Text(
          l10n.welcomeSubtitle,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize: 16.sp,
          ),
        ),
      ),
    );
  }
}
