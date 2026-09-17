/// The Read cards, and the meta line they share.
///
/// EVERY CARD CARRIES TWO LABELS, NOT ONE
///
/// A coloured chip for the KIND of writing, and a plain word for the part of
/// DSH it belongs to: "Opinion · Films · 23 Aug". They are different
/// questions and migration 034 added a second column rather than overloading
/// the first — `tag` is the chip, `section` is the word.
///
/// And each says up front whether it is free or behind a subscription, so a
/// reader learns that before tapping rather than after.
library;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/widgets/app_network_image.dart';
import 'package:dsh_mobile/layers/read/domain/entities/article.dart';
import 'package:dsh_mobile/layers/read/presentation/controllers/read_controller.dart';

/// The Read section's blue, from `ReadListing.tsx` — `rgba(93,148,185,0.7)`
/// on the chip. Not a DSH brand colour and not meant to be: Films and Studio
/// have the pink and the teal, and Read needed something that was neither.
const kReadBlue = Color(0xFF5D94B9);

String articleDate(DateTime when) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${when.day} ${months[when.month - 1]} ${when.year}';
}

/// chip · section · date · access.
///
/// Each piece is left out when it is empty, so a half-filled article shows a
/// short line rather than stray separators.
class ArticleMeta extends StatelessWidget {
  final Article article;

  /// Drops the chip — used where the chip is already drawn over the still.
  final bool withoutChip;

  const ArticleMeta({
    super.key,
    required this.article,
    this.withoutChip = false,
  });

  @override
  Widget build(BuildContext context) {
    final paid = article.access.isPaid;
    final tag = prettyTag(article.tag);

    return Wrap(
      spacing: 10.w,
      runSpacing: 6.h,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (!withoutChip && tag.isNotEmpty) ArticleTagChip(label: tag),
        if (article.section.trim().isNotEmpty)
          Text(
            article.section,
            style: TextStyle(color: AppColors.lightGrey, fontSize: 11.sp),
          ),
        Text(
          articleDate(article.date),
          style: TextStyle(color: AppColors.mediumGrey, fontSize: 11.sp),
        ),
        Text(
          paid ? 'Subscription only' : 'Free article',
          style: TextStyle(
            // Pink for paid, grey for free — the website's colours. Not green
            // for free: green would read as a state the reader achieved.
            color: paid ? AppColors.mainPurple : AppColors.mediumGrey,
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class ArticleTagChip extends StatelessWidget {
  final String label;

  const ArticleTagChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: kReadBlue.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(3.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.smoke,
          fontSize: 11.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// The featured article — the website's two-column block, stacked.
class FeaturedArticleCard extends StatelessWidget {
  final Article article;
  final VoidCallback onTap;

  const FeaturedArticleCard({
    super.key,
    required this.article,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(6.r);

    return InkWell(
      onTap: onTap,
      borderRadius: radius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: radius,
            child: AspectRatio(
              // 612 × 448 in the frame.
              aspectRatio: 612 / 448,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppNetworkImage(url: article.mainImageUrl),
                  // `grayscale(1) brightness(0.85)` on the website. The grade
                  // is what makes a dozen stills from a dozen sources read as
                  // one section rather than a contact sheet.
                  const ColoredBox(color: Color(0x26000000)),
                  if (prettyTag(article.tag).isNotEmpty)
                    PositionedDirectional(
                      top: 10.h,
                      start: 10.w,
                      child: ArticleTagChip(label: prettyTag(article.tag)),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            article.title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.smoke,
              fontSize: 22.sp,
              height: 1.25,
              letterSpacing: -0.57,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (!article.author.isEmpty) ...[
            SizedBox(height: 12.h),
            _Byline(author: article.author),
          ],
          if (article.excerpt.trim().isNotEmpty) ...[
            SizedBox(height: 10.h),
            Text(
              article.excerpt,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.mediumGrey,
                fontSize: 13.sp,
                height: 1.5,
              ),
            ),
          ],
          SizedBox(height: 14.h),
          ArticleMeta(article: article, withoutChip: true),
        ],
      ),
    );
  }
}

/// One row of the library.
class ArticleListCard extends StatelessWidget {
  final Article article;
  final VoidCallback onTap;

  const ArticleListCard({
    super.key,
    required this.article,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(6.r);

    return InkWell(
      onTap: onTap,
      borderRadius: radius,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 6.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: radius,
              child: SizedBox(
                width: 108.w,
                height: 84.h,
                child: AppNetworkImage(url: article.mainImageUrl, thumb: true),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ArticleMeta(article: article),
                  SizedBox(height: 8.h),
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.smoke,
                      fontSize: 14.sp,
                      height: 1.3,
                      letterSpacing: -0.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!article.author.isEmpty) ...[
                    SizedBox(height: 6.h),
                    Text(
                      'by ${article.author.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.mediumGrey,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Byline extends StatelessWidget {
  final ArticleAuthor author;

  const _Byline({required this.author});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipOval(
          child: SizedBox(
            width: 28.r,
            height: 28.r,
            child: AppNetworkImage(
              url: author.avatarUrl,
              thumb: true,
              // An author with no portrait gets their initials rather than an
              // empty grey disc, which reads as an image that failed.
              fallback: ColoredBox(
                color: AppColors.darkBackground,
                child: Center(
                  child: Text(
                    author.initials,
                    style: TextStyle(
                      color: AppColors.lightGrey,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            'by ${author.name}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.lightGrey, fontSize: 12.sp),
          ),
        ),
      ],
    );
  }
}
