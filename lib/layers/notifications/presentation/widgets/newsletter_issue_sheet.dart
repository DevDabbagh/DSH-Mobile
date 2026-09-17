/// Reading one issue, laid out like the email it was.
///
/// THE REFERENCE IS THE EMAIL, NOT THE WEBSITE
///
/// `newsletter-render.ts` is a separate renderer from the site's on purpose —
/// its own comments explain why: Gmail strips `<style>`, Outlook renders with
/// Word's engine, flexbox is a coin toss. So an issue has never looked like a
/// page on dontskiphumanity.com; it looks like that email. Matching the site
/// here would mean the thing a reader opens in the app is a third design of
/// something they already saw in their inbox.
///
/// So the ramp below is lifted from that renderer: text 16/26, h2 22, h3 18,
/// quote 18/28 italic behind a 3px DSH pink rule, caption 12/18 with a middle
/// dot, CTA a solid pink button. The only deliberate divergence is the
/// surface — an email is one column on #0D0D0D with no chrome, and this is a
/// sheet with a grabber and a title, because it is being opened rather than
/// received.
library;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/config/app_dimensions.dart';
import 'package:dsh_mobile/app/widgets/app_network_image.dart';
import 'package:dsh_mobile/layers/notifications/domain/entities/newsletter_issue.dart';

class NewsletterIssueSheet extends StatelessWidget {
  final NewsletterIssue issue;

  const NewsletterIssueSheet({super.key, required this.issue});

  static Future<void> show(BuildContext context, NewsletterIssue issue) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => NewsletterIssueSheet(issue: issue),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) => Container(
        decoration: BoxDecoration(
          color: AppColors.deepBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          border: Border.all(
            color: AppColors.white.withValues(alpha: 0.08),
            width: 1.2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListView(
          controller: controller,
          padding: EdgeInsets.fromLTRB(
            AppDimensions.pagePadding.w,
            10.h,
            AppDimensions.pagePadding.w,
            32.h,
          ),
          children: [
            Center(
              child: Container(
                width: 38.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 18.h),
            Text(
              issue.subject,
              style: TextStyle(
                color: AppColors.white,
                fontSize: 20.sp,
                height: 1.3,
                letterSpacing: -0.4,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (issue.preheader.trim().isNotEmpty) ...[
              SizedBox(height: 8.h),
              Text(
                issue.preheader,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13.sp,
                  height: 1.55,
                ),
              ),
            ],
            SizedBox(height: 18.h),
            Divider(color: AppColors.white.withValues(alpha: 0.06), height: 1),
            SizedBox(height: 18.h),
            if (issue.body.isEmpty)
              Text(
                // An issue whose blocks this app could not read. Better to say
                // so than to show a blank sheet that looks like a failure to
                // load.
                'This issue has nothing the app can display.',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12.sp,
                  height: 1.5,
                ),
              )
            else
              for (final block in issue.body) _Block(block: block),
          ],
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  final NewsletterBlock block;

  const _Block({required this.block});

  @override
  Widget build(BuildContext context) {
    switch (block.type) {
      // 22 and 18 in the email, with 28 above and 12 below.
      case NewsletterBlockType.heading:
        return Padding(
          padding: EdgeInsets.only(top: 28.h, bottom: 12.h),
          child: Text(
            block.content,
            style: TextStyle(
              color: AppColors.smoke,
              fontSize: block.level == 3 ? 18.sp : 22.sp,
              height: 1.3,
              fontWeight: FontWeight.bold,
            ),
          ),
        );

      case NewsletterBlockType.text:
      // An editor's pasted HTML, with the tags taken out. Rendering it
      // properly would mean a full HTML renderer for a case that is rare and
      // usually a link or a bit of bold; dropping it would leave a hole in
      // the middle of an issue.
      case NewsletterBlockType.html:
        final text = block.type == NewsletterBlockType.html
            ? _stripTags(block.content)
            : block.content;

        // Blank lines become paragraphs, as `paragraphs()` does in the
        // renderer. One Text with the newlines left in it would set the gap
        // between paragraphs to the line height, which is why an issue read
        // as a wall here and as prose in the inbox.
        final paras = text
            .split(RegExp(r'\n{2,}'))
            .map((p) => p.trim())
            .where((p) => p.isNotEmpty);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final p in paras)
              Padding(
                padding: EdgeInsets.only(bottom: 16.h),
                child: Text(
                  p,
                  // 16/26 and #F0F0F0 — the email's body is the reader's
                  // text, not a caption, and it was set here at 13px grey.
                  style: TextStyle(
                    color: AppColors.smoke,
                    fontSize: 16.sp,
                    height: 1.625,
                  ),
                ),
              ),
          ],
        );

      case NewsletterBlockType.cta:
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Material(
              color: AppColors.mainPurple,
              borderRadius: BorderRadius.circular(3.r),
              child: InkWell(
                borderRadius: BorderRadius.circular(3.r),
                onTap: () => _open(context, block.url),
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 28.w, vertical: 14.h),
                  child: Text(
                    block.content,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

      case NewsletterBlockType.image:
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child: AppNetworkImage(url: block.content, fit: BoxFit.contain),
              ),
              if (block.caption.isNotEmpty || block.credit.isNotEmpty) ...[
                SizedBox(height: 8.h),
                Text(
                  // A middle dot, as the email joins them. An em dash reads
                  // as an aside; the dot reads as two facts.
                  [block.caption, block.credit]
                      .where((s) => s.trim().isNotEmpty)
                      .join(' · '),
                  style: TextStyle(
                    color: AppColors.mediumGrey,
                    fontSize: 12.sp,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        );

      case NewsletterBlockType.quote:
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 28.h),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // A flat 3px pink rule, not the brand gradient. The email
                // uses `border-left:3px solid #B23495` — a gradient is not a
                // thing a mail client can be relied on to draw, so the issue
                // as sent has a solid one and this should match it.
                Container(width: 3.w, color: AppColors.mainPurple),
                SizedBox(width: 18.w),
                Expanded(
                  child: Text(
                    block.content,
                    style: TextStyle(
                      color: AppColors.smoke,
                      fontSize: 18.sp,
                      height: 1.55,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

      case NewsletterBlockType.divider:
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 32.h),
          child: Container(
            // Full width and a hairline, as the email draws it. The short
            // centred gradient rule here was a flourish the issue never had.
            height: 1,
            color: AppColors.smoke.withValues(alpha: 0.10),
          ),
        );

      case NewsletterBlockType.unknown:
        // Filtered out by the model, so this is unreachable — but a switch
        // that returns nothing for a case is how a silent blank appears the
        // day the filter changes.
        return const SizedBox.shrink();
    }
  }

  /// Opens a CTA's destination in the browser.
  ///
  /// `externalApplication` rather than an in-app webview: these links go to
  /// the website, a partner, or a ticket page, and a reader who is already
  /// signed in on their own browser should land signed in.
  static Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.tryParse(url.trim());
    // Only http(s). A `javascript:` or `intent:` URL in a block an editor
    // pasted should not be handed to the platform to interpret.
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) return;

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (ok || !context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: const Text('Could not open that link.'),
        backgroundColor: AppColors.cardSurface,
        behavior: SnackBarBehavior.floating,
      ));
  }

  /// Tags out, entities back to characters, runs of whitespace collapsed.
  ///
  /// Not an HTML parser and not trying to be. Block elements become newlines
  /// first so paragraphs do not run into each other, which is the one thing a
  /// naïve strip gets visibly wrong.
  static String _stripTags(String html) {
    final withBreaks = html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</(p|div|li|h[1-6])>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '• ');

    return withBreaks
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }
}
