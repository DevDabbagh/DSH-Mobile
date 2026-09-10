import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:dsh_mobile/app/widgets/app_network_image.dart';
import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/l10n/app_localizations.dart';
import 'package:dsh_mobile/layers/studio/domain/entities/studio_project.dart';

/// What the Studio offers, as four fixed cards.
///
/// These are not database rows and deliberately so: they describe the
/// Studio's standing capabilities, not its catalogue, and the website states
/// them the same way. They are localised, so all three languages stay in
/// step, but they do not change when the catalogue does.
enum StudioCapability {
  docuseries,
  podcasts,
  production,
  series;

  /// The format whose projects illustrate this capability. Production has no
  /// single format — it is how the work gets made, not a kind of work.
  StudioFormat? get illustratedBy {
    switch (this) {
      case StudioCapability.docuseries:
        return StudioFormat.docuseries;
      case StudioCapability.podcasts:
        return StudioFormat.podcast;
      case StudioCapability.series:
        return StudioFormat.series;
      case StudioCapability.production:
        return null;
    }
  }

  IconData get icon {
    switch (this) {
      case StudioCapability.docuseries:
        return Icons.video_library_outlined;
      case StudioCapability.podcasts:
        return Icons.mic_none_outlined;
      case StudioCapability.production:
        return Icons.movie_filter_outlined;
      case StudioCapability.series:
        return Icons.grid_view_outlined;
    }
  }

  String title(AppLocalizations l10n) {
    switch (this) {
      case StudioCapability.docuseries:
        return l10n.studioCapDocuseriesTitle;
      case StudioCapability.podcasts:
        return l10n.studioCapPodcastsTitle;
      case StudioCapability.production:
        return l10n.studioCapProductionTitle;
      case StudioCapability.series:
        return l10n.studioCapSeriesTitle;
    }
  }

  String body(AppLocalizations l10n) {
    switch (this) {
      case StudioCapability.docuseries:
        return l10n.studioCapDocuseriesBody;
      case StudioCapability.podcasts:
        return l10n.studioCapPodcastsBody;
      case StudioCapability.production:
        return l10n.studioCapProductionBody;
      case StudioCapability.series:
        return l10n.studioCapSeriesBody;
    }
  }

  /// "01" … "04", as the design numbers them.
  String get ordinal => (index + 1).toString().padLeft(2, '0');
}

/// The row of four circular capability buttons under "WHAT STUDIO DOES".
class StudioCapabilityRow extends StatelessWidget {
  final ValueChanged<StudioCapability> onSelect;

  const StudioCapabilityRow({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final c in StudioCapability.values)
          Expanded(
            child: GestureDetector(
              onTap: () => onSelect(c),
              behavior: HitTestBehavior.opaque,
              child: Column(
                children: [
                  Container(
                    width: 46.w,
                    height: 46.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.cardSurface.withValues(alpha: 0.88),
                      border: Border.all(
                        color: AppColors.smoke.withValues(alpha: 0.10),
                        width: 0.8,
                      ),
                    ),
                    child: Icon(
                      c.icon,
                      size: 19.w,
                      color: AppColors.smoke,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    c.title(l10n),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    // Figma 2219:1492 — 10px, white at 40%, regular.
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.4),
                      fontSize: 10.sp,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// The sheet that opens when a capability is tapped.
///
/// [imageUrl] is the cover of a real project in that format rather than a
/// bundled asset — the Studio's own work illustrating what the Studio does,
/// and nothing to ship or keep in sync. It is null when nothing published
/// matches, and the sheet then opens without a header image.
class StudioCapabilitySheet extends StatelessWidget {
  final StudioCapability capability;
  final String? imageUrl;

  const StudioCapabilitySheet({
    super.key,
    required this.capability,
    this.imageUrl,
  });

  static Future<void> show(
    BuildContext context, {
    required StudioCapability capability,
    String? imageUrl,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.black.withValues(alpha: 0.7),
      isScrollControlled: true,
      // The tab bar lives above the shell's navigator, so a sheet opened on
      // the branch navigator comes up *underneath* it. The root navigator
      // covers the whole app, which is what a modal should do.
      useRootNavigator: true,
      builder: (_) => StudioCapabilitySheet(
        capability: capability,
        imageUrl: imageUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final url = imageUrl;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.deepBackground,
        borderRadius: BorderRadiusDirectional.only(
          topStart: Radius.circular(14.r),
          topEnd: Radius.circular(14.r),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Container(
                width: 34.w,
                height: 3.h,
                decoration: BoxDecoration(
                  color: AppColors.mediumGrey,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            if (url != null)
              SizedBox(
                height: 190.h,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppNetworkImage(
                      url: url,
                      fit: BoxFit.cover,
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x000D0D0D),
                            Color(0xCC0D0D0D),
                            AppColors.deepBackground,
                          ],
                          stops: [0.45, 0.85, 1.0],
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      start: 18.w,
                      bottom: 8.h,
                      child: Text(
                        capability.ordinal,
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.85),
                          fontSize: 26.sp,
                          height: 1.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 18.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    capability.title(l10n),
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 18.sp,
                      height: 1.3,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    capability.body(l10n),
                    style: TextStyle(
                      color: AppColors.lightGrey,
                      fontSize: 12.sp,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: double.infinity,
                      height: 42.h,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.mediumBackground,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        l10n.studioClose,
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 12.sp,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
