import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/layers/films/presentation/controllers/films_controller.dart';
import 'package:dsh_mobile/layers/studio/presentation/controllers/studio_controller.dart';
import 'package:dsh_mobile/layers/support/domain/entities/donation.dart';

part 'funded_project_card.g.dart';

/// The poster for the project a donor arrived to fund.
///
/// The route carries only type, slug and title — a URL is a bad place to keep
/// an image, and pinning one there would freeze the poster to whatever it was
/// the day the link was made. So the picture is looked up here, from the same
/// providers the film and studio screens already use, which usually means it
/// is already cached and appears instantly.
///
/// Returns null on any failure. **A missing poster must never block a
/// donation** — the card falls back to the title, which the route already gave
/// us, and the money still moves.
@riverpod
Future<String?> fundedProjectImage(
  Ref ref, {
  required String type,
  required String slug,
}) async {
  try {
    switch (type) {
      case 'film':
        final film = await ref.watch(filmBySlugProvider(slug).future);
        final url = film?.cardImageUrl ?? '';
        return url.isEmpty ? null : url;

      case 'studio':
        final project =
            await ref.watch(studioProjectBySlugProvider(slug).future);
        final url = project?.coverUrl.isNotEmpty == true
            ? project!.coverUrl
            : (project?.thumbnailUrl ?? '');
        return url.isEmpty ? null : url;

      // Academy is an allowed fund type on the server but has no lookup on
      // this side yet. Title-only is correct until it does.
      default:
        return null;
    }
  } catch (_) {
    return null;
  }
}

/// Shown above the amounts: this is what the money is for.
class FundedProjectCard extends ConsumerWidget {
  final FundingTarget target;
  const FundedProjectCard(this.target, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final image = ref
        .watch(fundedProjectImageProvider(type: target.type, slug: target.slug))
        .valueOrNull;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: AppColors.deepBackground,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(
          color: AppColors.smoke.withValues(alpha: 0.10),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          if (image != null)
            Image.network(
              image,
              width: 64.w,
              height: 64.w,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => SizedBox(width: 64.w, height: 64.w),
            ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'You are supporting',
                    style: TextStyle(
                      color: AppColors.mediumGrey,
                      fontSize: 10.sp,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    target.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.smoke,
                      fontSize: 14.sp,
                      height: 19 / 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
