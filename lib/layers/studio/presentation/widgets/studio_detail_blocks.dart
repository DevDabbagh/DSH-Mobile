import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:dsh_mobile/app/widgets/app_network_image.dart';
import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/l10n/app_localizations.dart';
import 'package:dsh_mobile/layers/studio/domain/entities/studio_project.dart';

/// The stills carousel: one image at a time, arrows on either side, dots
/// underneath. Swipeable as well as tappable, because a carousel you can only
/// drive with 28px arrows is a carousel most people never reach the end of.
class StillsCarousel extends StatefulWidget {
  final List<String> urls;

  const StillsCarousel({super.key, required this.urls});

  @override
  State<StillsCarousel> createState() => _StillsCarouselState();
}

class _StillsCarouselState extends State<StillsCarousel> {
  late final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int delta) {
    final next = (_index + delta).clamp(0, widget.urls.length - 1);
    if (next == _index) return;
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 215.h,
          child: Stack(
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: widget.urls.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => AppNetworkImage(
                  url: widget.urls[i],
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
              if (widget.urls.length > 1) ...[
                PositionedDirectional(
                  start: 8.w,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _ArrowButton(
                      // Directional: in Arabic the leading edge is on the
                      // right, and "previous" must still point back.
                      icon: Icons.chevron_left,
                      enabled: _index > 0,
                      onTap: () => _go(-1),
                    ),
                  ),
                ),
                PositionedDirectional(
                  end: 8.w,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _ArrowButton(
                      icon: Icons.chevron_right,
                      enabled: _index < widget.urls.length - 1,
                      onTap: () => _go(1),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (widget.urls.length > 1) ...[
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.urls.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: EdgeInsets.symmetric(horizontal: 2.w),
                  // The active dot stretches into a bar — position is easier
                  // to read at a glance than a brightness difference.
                  width: i == _index ? 16.w : 4.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: i == _index
                        ? AppColors.smoke
                        : AppColors.smoke.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _ArrowButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 28.w,
          height: 28.w,
          decoration: BoxDecoration(
            color: AppColors.deepBackground.withValues(alpha: 0.72),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.smoke.withValues(alpha: 0.10),
              width: 1.2,
            ),
          ),
          child: Icon(icon, size: 14.w, color: AppColors.smoke),
        ),
      ),
    );
  }
}

/// The credits table: a wide uppercase label column and a value column,
/// hairline rules top and bottom.
class StudioCreditsTable extends StatelessWidget {
  final List<({String label, String value})> rows;

  const StudioCreditsTable({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 16.h, bottom: 4.h),
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(
            color: AppColors.smoke.withValues(alpha: 0.06),
            width: 0.6,
          ),
        ),
      ),
      child: Column(
        children: [
          for (final r in rows)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 118.w,
                    child: Text(
                      r.label.toUpperCase(),
                      style: TextStyle(
                        color: AppColors.mediumBackground,
                        fontSize: 10.sp,
                        height: 1.5,
                        letterSpacing: 1.8,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      r.value,
                      style: TextStyle(
                        color: AppColors.smoke,
                        fontSize: 12.sp,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// One episode.
///
/// "View episode" is live only when the episode actually has a video; the rest
/// are dimmed rather than hidden, so the shape of the season is visible even
/// before everything is published.
class EpisodeCard extends StatelessWidget {
  final StudioEpisode episode;
  final VoidCallback? onView;
  final VoidCallback? onKnowMore;

  const EpisodeCard({
    super.key,
    required this.episode,
    this.onView,
    this.onKnowMore,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.cardSurface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(
          color: AppColors.smoke.withValues(alpha: 0.10),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((episode.imageUrl ?? '').isNotEmpty)
            SizedBox(
              height: 185.h,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppNetworkImage(
                    url: episode.imageUrl!,
                    fit: BoxFit.cover,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0xA60D0D0D), Color(0x000D0D0D)],
                        stops: [0.0, 0.55],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 13.h, 16.w, 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_meta(l10n).isNotEmpty)
                  Text(
                    _meta(l10n),
                    style: TextStyle(
                      color: AppColors.lightGrey,
                      fontSize: 11.sp,
                      height: 1.5,
                    ),
                  ),
                SizedBox(height: 6.h),
                Text(
                  episode.title,
                  style: TextStyle(
                    color: AppColors.smoke,
                    fontSize: 17.sp,
                    height: 1.3,
                    letterSpacing: -0.3,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if ((episode.subtitle ?? '').isNotEmpty) ...[
                  SizedBox(height: 3.h),
                  Text(
                    episode.subtitle!,
                    style: TextStyle(
                      color: AppColors.lightGrey,
                      fontSize: 13.sp,
                      height: 1.5,
                    ),
                  ),
                ],
                if ((episode.guest ?? '').isNotEmpty) ...[
                  SizedBox(height: 5.h),
                  Text(
                    l10n.studioGuest(episode.guest!),
                    style: TextStyle(
                      color: AppColors.mediumGrey,
                      fontSize: 11.sp,
                      height: 1.5,
                    ),
                  ),
                ],
                if (episode.description.trim().isNotEmpty) ...[
                  SizedBox(height: 9.h),
                  Text(
                    episode.description,
                    style: TextStyle(
                      color: AppColors.mediumGrey,
                      fontSize: 13.sp,
                      height: 1.46,
                    ),
                  ),
                ],
                SizedBox(height: 14.h),
                Row(
                  children: [
                    Expanded(
                      child: _EpisodeAction(
                        label: l10n.studioViewEpisode,
                        icon: Icons.play_arrow_rounded,
                        // Nothing to play yet — dimmed and inert rather than
                        // opening a page with an empty player.
                        enabled: episode.hasVideo,
                        filled: true,
                        onTap: episode.hasVideo ? onView : null,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: _EpisodeAction(
                        label: l10n.studioKnowMore,
                        enabled: true,
                        filled: false,
                        onTap: onKnowMore,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// "Episode 1 · Season 1 · 42 min", dropping whichever parts are unknown.
  String _meta(AppLocalizations l10n) {
    final parts = <String>[
      if (episode.number != null) l10n.studioEpisodeNumber('${episode.number}'),
      if (episode.season != null) l10n.studioSeasonNumber('${episode.season}'),
      if ((episode.duration ?? '').isNotEmpty) episode.duration!,
    ];
    return parts.join(' · ');
  }
}

class _EpisodeAction extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool enabled;
  final bool filled;
  final VoidCallback? onTap;

  const _EpisodeAction({
    required this.label,
    required this.enabled,
    required this.filled,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground =
        filled && enabled ? AppColors.smoke : AppColors.lightGrey;

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          height: 36.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: filled && enabled ? AppColors.primaryGradient : null,
            color: filled && !enabled
                ? AppColors.smoke.withValues(alpha: 0.04)
                : null,
            borderRadius: BorderRadius.circular(3.r),
            border: filled && enabled
                ? null
                : Border.all(
                    color: AppColors.smoke.withValues(alpha: 0.10),
                    width: 1.2,
                  ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 10.w, color: foreground),
                SizedBox(width: 6.w),
              ],
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 12.sp,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
