import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/config/app_dimensions.dart';
import 'package:dsh_mobile/app/supabase/section_header.dart';
import 'package:dsh_mobile/app/widgets/segmented_headline.dart';
import 'package:dsh_mobile/l10n/app_localizations.dart';

/// The standfirst under a section hero's headline — one line, with the rest
/// of it behind "See more".
///
/// WHY ONE LINE
///
/// The website prints the whole paragraph beside a hero the height of a
/// browser window. Here it sits between the headline and two buttons on a
/// 300-pixel image, and at three lines it pushed the buttons onto the black
/// below. One line keeps the hero the shape the frame draws; "See more" is
/// what stops that being a truncation with nowhere to go.
///
/// Shared by Films and Studio because both heroes have exactly this problem
/// and exactly these three fields. The first version lived inside the Films
/// screen, which is how Studio ended up printing its paragraph in full while
/// Films truncated its own.
class SectionHeaderBody extends StatelessWidget {
  final SectionHeader header;

  /// Shown when the dashboard's description is empty. The app's own
  /// translation of whatever the website falls back to for this section.
  final String fallbackBody;

  /// The headline, repeated inside the sheet so it opens with the words that
  /// were tapped rather than with the paragraph alone.
  final List<({String text, bool highlight})> headlineSegments;

  const SectionHeaderBody({
    super.key,
    required this.header,
    required this.fallbackBody,
    required this.headlineSegments,
  });

  String get _body =>
      header.description.isNotEmpty ? header.description : fallbackBody;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_body.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => _SectionHeaderSheet.show(
        context,
        body: _body,
        segments: headlineSegments,
      ),
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(
              _body,
              style: TextStyle(
                color: AppColors.mediumGrey,
                fontSize: 12.sp,
                height: 1.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 6.w),
          // Quiet, and the same size as the line it ends. It was bold white
          // at full size, which made it the loudest thing in the hero —
          // louder than the headline above it. This is a footnote on a
          // truncated sentence, not a call to action.
          Text(
            l10n.headerSeeMore,
            style: TextStyle(
              color: AppColors.lightGrey,
              fontSize: 11.sp,
              height: 1.5,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.lightGrey.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// The header in full, once someone has asked for it.
class _SectionHeaderSheet extends StatelessWidget {
  final String body;
  final List<({String text, bool highlight})> segments;

  const _SectionHeaderSheet({required this.body, required this.segments});

  static Future<void> show(
    BuildContext context, {
    required String body,
    required List<({String text, bool highlight})> segments,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      // The ROOT navigator, not the tab branch's.
      //
      // A sheet mounted on the branch navigator sits inside the tab shell,
      // and the floating tab bar is drawn by the shell — above it. So the
      // sheet came up underneath the nav pill with its text running behind
      // the icons. A modal belongs over the whole shell.
      useRootNavigator: true,
      builder: (_) => _SectionHeaderSheet(body: body, segments: segments),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.deepBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(14.r)),
        border: Border(
          top: BorderSide(color: AppColors.smoke.withValues(alpha: 0.10)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppDimensions.pagePadding.w,
            10.h,
            AppDimensions.pagePadding.w,
            24.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.mediumGrey,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              SizedBox(height: 22.h),

              // The same runs the hero drew, so the gradient and the wording
              // match what was tapped. No line cap here — the sheet is where
              // the headline is allowed its full height.
              SegmentedHeadline(
                segments: segments,
                style: TextStyle(
                  color: AppColors.smoke,
                  fontSize: 24.sp,
                  height: 1.25,
                  letterSpacing: -0.6,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 14.h),
              // Scrollable rather than capped: this is the one place the
              // paragraph is allowed to be as long as the editor wrote it,
              // and a sheet that truncates is a sheet with no purpose.
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.45,
                ),
                child: SingleChildScrollView(
                  child: Text(
                    body,
                    style: TextStyle(
                      color: AppColors.lightGrey,
                      fontSize: 13.sp,
                      height: 20 / 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
