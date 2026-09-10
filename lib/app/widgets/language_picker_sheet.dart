import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/config/app_dimensions.dart';
import 'package:dsh_mobile/app/localization/locale_controller.dart';

/// The languages offered, in the order they appear.
///
/// Names are written in each language rather than translated — someone
/// looking for Arabic is looking for "العربية", not "Arabic" rendered in a
/// language they can't read.
const _languageNames = <String, String>{
  'en': 'English',
  'pt': 'Português',
  'ar': 'العربية',
};

/// The display name for [code], falling back to the code itself so a newly
/// added .arb file still shows something sensible before it's named here.
String languageLabel(String code) => _languageNames[code] ?? code.toUpperCase();

/// Bottom sheet for switching the app language.
///
/// Selecting one writes it to preferences and rebuilds the app: interface
/// strings come from the .arb files, content is refetched from Supabase in
/// the same language.
class LanguagePickerSheet extends ConsumerWidget {
  const LanguagePickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => const LanguagePickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeControllerProvider).languageCode;
    final codes = LocaleController.supportedCodes;

    return SafeArea(
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(
          vertical: AppDimensions.pagePadding.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Grab handle
            Center(
              child: Container(
                width: 36.w,
                height: 4.h,
                margin: EdgeInsetsDirectional.only(bottom: 20.h),
                decoration: BoxDecoration(
                  color: AppColors.textMuted,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),

            ...codes.map((code) {
              final selected = code == current;

              return InkWell(
                onTap: () async {
                  await ref
                      .read(localeControllerProvider.notifier)
                      .setLocale(code);
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: Padding(
                  padding: EdgeInsetsDirectional.symmetric(
                    horizontal: AppDimensions.pagePadding.w,
                    vertical: 16.h,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          languageLabel(code),
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 15.sp,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (selected)
                        Icon(
                          Icons.check,
                          color: AppColors.mainPurple,
                          size: 20.w,
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
