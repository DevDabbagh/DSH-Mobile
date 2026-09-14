import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/widgets/app_network_image.dart';
import 'package:dsh_mobile/app/supabase/media_url.dart';
import 'package:dsh_mobile/layers/pages/domain/entities/page_section.dart';

/// Renderers for the section kinds the Pages editor can produce.
///
/// One widget per `kind`, chosen by [buildPageSection]. A kind with no widget
/// here renders nothing — the dashboard may gain a kind before the app ships a
/// widget for it, and a reader should lose that one section rather than the
/// screen.
///
/// THE FIELD NAMES HERE ARE NOT GUESSES. Every key is the one written by the
/// seed migrations (`026_page_sections.sql`, `028`, `029`, `030`) and read by
/// the website. Getting one wrong does not raise an error — the value comes
/// back empty and the block silently renders nothing, which is how the first
/// draft of this file lost three of About's six sections. If you add a field,
/// read the migration; do not infer it from the widget above.
///
/// Every text value arrives already resolved into the reader's language by
/// `PageSectionModel`, so nothing here calls `pickLang`. Images arrive as
/// stored — often site-relative, e.g. `/images/note.jpg` — so they go through
/// `resolveMediaUrl`, which is meaningless off the website.

const _pagePad = 20.0;

/// Every route the app can push. A `linkHref` naming anything else is treated
/// as external, and one naming nothing renders as plain text rather than as a
/// button that does nothing — the editor leaves `linkHref` empty on purpose
/// (all three "Other ways to contribute" items ship that way).
const _knownRoutes = {
  '/films',
  '/studio',
  '/academy',
  '/read',
  '/about',
  '/events',
  '/discover',
  '/home',
  '/support',
};

Widget? buildPageSection(PageSection s) {
  switch (s.kind) {
    case 'hero':
      return _HeroBlock(s);
    case 'intro':
      return _IntroBlock(s);
    case 'numbered_list':
      return _NumberedListBlock(s);
    case 'split_prose':
      return _SplitProseBlock(s);
    case 'pillars':
      return _PillarsBlock(s);
    case 'people':
      return _PeopleBlock(s);
    case 'stats':
      return _StatsBlock(s);
    case 'cards':
      return _CardsBlock(s);
    case 'quote':
      return _QuoteBlock(s);
    case 'cta':
      return _CtaBlock(s);
    default:
      return null;
  }
}

/* ── shared pieces ──────────────────────────────────────────────────── */

/// Section heading — the small line the editor calls `label`.
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: TextStyle(
          color: AppColors.mediumGrey,
          fontSize: 11.sp,
          letterSpacing: 1.8,
          fontWeight: FontWeight.w600,
        ),
      );
}

/// The 40×2 teal→pink rule that opens a section.
class _GradientRule extends StatelessWidget {
  const _GradientRule();

  @override
  Widget build(BuildContext context) => Container(
        width: 40.w,
        height: 2.h,
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
      );
}

/// A remote image with a flat placeholder — never a broken-image glyph, and
/// never an empty box where a caller passed nothing.
class _Img extends StatelessWidget {
  final String src;
  final double? width;
  final double height;
  const _Img(this.src, {this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    final url = resolveMediaUrl(src);
    if (url.isEmpty) return const SizedBox.shrink();

    // Was Image.network — no disk cache, so scrolling a page section back
    // into view fetched every image again.
    return AppNetworkImage(
      url: url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      fallback: Container(
        width: width,
        height: height,
        color: AppColors.darkBackground,
      ),
    );
  }
}

/// Follows an editor-authored href. In-app where the app has the screen,
/// browser where it does not.
Future<void> _follow(BuildContext context, String href) async {
  final target = href.trim();
  if (target.isEmpty) return;

  if (target.startsWith('/')) {
    // Match on the first path segment so `/films/some-slug` still routes.
    final segments = target.split('/').where((p) => p.isNotEmpty);
    final root = segments.isEmpty ? '' : '/${segments.first}';
    if (_knownRoutes.contains(root)) {
      context.push(target);
      return;
    }
  }

  final uri = Uri.tryParse(
    target.startsWith('http') ? target : resolveMediaUrl(target),
  );
  if (uri != null) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// A text link — rendered only when it has both a label and somewhere to go.
class _LinkText extends StatelessWidget {
  final String label;
  final String href;
  const _LinkText({required this.label, required this.href});

  @override
  Widget build(BuildContext context) {
    if (label.trim().isEmpty || href.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: GestureDetector(
        onTap: () => _follow(context, href),
        child: Text(
          '$label →',
          style: TextStyle(
            color: AppColors.mainPurple,
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Read a translated string out of a repeater item.
String _s(Map<String, dynamic> m, String key) {
  final v = m[key];
  return v is String ? v : '';
}

/* ── hero ───────────────────────────────────────────────────────────── */

/// `eyebrow` · `headline` · `standfirst` · `imageSrc` · `facts[{text}]`
///
/// `facts` is Support's only — About's hero has none, and an absent list simply
/// renders nothing rather than an empty bullet run.
class _HeroBlock extends StatelessWidget {
  final PageSection s;
  const _HeroBlock(this.s);

  @override
  Widget build(BuildContext context) {
    final eyebrow = s.str('eyebrow');
    final headline = s.str('headline');
    final standfirst = s.str('standfirst');
    final image = resolveMediaUrl(s.str('imageSrc'));
    final facts = s.list('facts');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (image.isNotEmpty) ...[
          _Img(s.str('imageSrc'), height: 180.h, width: double.infinity),
          SizedBox(height: 20.h),
        ],
        Padding(
          padding: EdgeInsets.fromLTRB(
              _pagePad.w, image.isEmpty ? 8.h : 0, _pagePad.w, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow.isNotEmpty) ...[
                SectionLabel(eyebrow),
                SizedBox(height: 12.h),
              ],
              if (headline.isNotEmpty)
                Text(
                  headline,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 26.sp,
                    height: 34 / 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              if (standfirst.isNotEmpty) ...[
                SizedBox(height: 12.h),
                Text(
                  standfirst,
                  style: TextStyle(
                    color: AppColors.lightGrey,
                    fontSize: 14.sp,
                    height: 22 / 14,
                  ),
                ),
              ],
              for (final f in facts)
                if (_s(f, 'text').isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 10.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 7.h),
                          child: Container(
                            width: 4.w,
                            height: 4.w,
                            decoration: const BoxDecoration(
                              color: AppColors.mainBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            _s(f, 'text'),
                            style: TextStyle(
                              color: AppColors.mediumGrey,
                              fontSize: 12.sp,
                              height: 18 / 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

/* ── intro ──────────────────────────────────────────────────────────── */

/// `body` — one paragraph, nothing else.
class _IntroBlock extends StatelessWidget {
  final PageSection s;
  const _IntroBlock(this.s);

  @override
  Widget build(BuildContext context) {
    final body = s.str('body');
    if (body.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(_pagePad.w, 28.h, _pagePad.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _GradientRule(),
          SizedBox(height: 14.h),
          Text(
            body,
            style: TextStyle(
              color: AppColors.lightGrey,
              fontSize: 15.sp,
              height: 24 / 15,
            ),
          ),
        ],
      ),
    );
  }
}

/* ── numbered_list ──────────────────────────────────────────────────── */

/// `label` · `items[{num, title, desc, linkLabel, linkHref}]`
///
/// `num` is empty on Support's "Other ways to contribute" and set on About's
/// "What we do", so the number column appears only when there is a number.
class _NumberedListBlock extends StatelessWidget {
  final PageSection s;
  const _NumberedListBlock(this.s);

  @override
  Widget build(BuildContext context) {
    final items = s.list('items');
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(_pagePad.w, 32.h, _pagePad.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (s.str('label').isNotEmpty) ...[
            SectionLabel(s.str('label')),
            SizedBox(height: 16.h),
          ],
          for (final it in items)
            Container(
              margin: EdgeInsets.only(bottom: 10.h),
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(
                  color: AppColors.smoke.withValues(alpha: 0.10),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      if (_s(it, 'num').isNotEmpty) ...[
                        Text(
                          _s(it, 'num'),
                          style: TextStyle(
                            color: AppColors.mainPurple,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 10.w),
                      ],
                      Expanded(
                        child: Text(
                          _s(it, 'title'),
                          style: TextStyle(
                            color: AppColors.smoke,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_s(it, 'desc').isNotEmpty) ...[
                    SizedBox(height: 6.h),
                    Text(
                      _s(it, 'desc'),
                      style: TextStyle(
                        color: AppColors.mediumGrey,
                        fontSize: 12.sp,
                        height: 19 / 12,
                      ),
                    ),
                  ],
                  _LinkText(
                    label: _s(it, 'linkLabel'),
                    href: _s(it, 'linkHref'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/* ── split_prose ────────────────────────────────────────────────────── */

/// `headlineNormal` + `headlineAccent` + `headlineAfter` · `imageSrc` ·
/// `paragraphs[]` · `quote`
///
/// The web sets this side by side; on a phone it stacks. The headline is three
/// fields because the middle word is coloured — that is the whole reason it is
/// split, so it must not be re-joined into one string here.
class _SplitProseBlock extends StatelessWidget {
  final PageSection s;
  const _SplitProseBlock(this.s);

  @override
  Widget build(BuildContext context) {
    final paras = s.paragraphs('paragraphs');
    final quote = s.str('quote');
    final normal = s.str('headlineNormal');
    final accent = s.str('headlineAccent');
    final after = s.str('headlineAfter');

    if (paras.isEmpty && quote.isEmpty && accent.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 32.h),
        _Img(s.str('imageSrc'), height: 200.h, width: double.infinity),
        Padding(
          padding: EdgeInsets.fromLTRB(_pagePad.w, 20.h, _pagePad.w, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (normal.isNotEmpty || accent.isNotEmpty || after.isNotEmpty)
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 22.sp,
                      height: 30 / 22,
                      fontWeight: FontWeight.w700,
                    ),
                    children: [
                      if (normal.isNotEmpty) TextSpan(text: '$normal '),
                      if (accent.isNotEmpty)
                        TextSpan(
                          text: accent,
                          style: const TextStyle(color: AppColors.mainPurple),
                        ),
                      if (after.isNotEmpty) TextSpan(text: ' $after'),
                    ],
                  ),
                ),
              for (final p in paras) ...[
                SizedBox(height: 14.h),
                Text(
                  p,
                  style: TextStyle(
                    color: AppColors.mediumGrey,
                    fontSize: 13.sp,
                    height: 21 / 13,
                  ),
                ),
              ],
              if (quote.isNotEmpty) ...[
                SizedBox(height: 18.h),
                Container(
                  padding: EdgeInsets.only(left: 14.w),
                  decoration: const BoxDecoration(
                    border: Border(
                      left: BorderSide(color: AppColors.purpleDark2, width: 2),
                    ),
                  ),
                  child: Text(
                    quote,
                    style: TextStyle(
                      color: AppColors.smoke,
                      fontSize: 15.sp,
                      height: 24 / 15,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/* ── pillars ────────────────────────────────────────────────────────── */

/// `label` · `headlineNormal` + `headlineAccent` · `ctaLabel` · `ctaHref` ·
/// `items[{num, name, desc}]`
///
/// Note `name`, not `title` — pillars and numbered_list differ here, and the
/// two are easy to conflate.
class _PillarsBlock extends StatelessWidget {
  final PageSection s;
  const _PillarsBlock(this.s);

  @override
  Widget build(BuildContext context) {
    final items = s.list('items');
    final normal = s.str('headlineNormal');
    final accent = s.str('headlineAccent');
    if (items.isEmpty && normal.isEmpty && accent.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(_pagePad.w, 32.h, _pagePad.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (s.str('label').isNotEmpty) ...[
            SectionLabel(s.str('label')),
            SizedBox(height: 12.h),
          ],
          if (normal.isNotEmpty)
            Text(
              normal,
              style: TextStyle(
                color: AppColors.white,
                fontSize: 20.sp,
                height: 28 / 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          if (accent.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              accent,
              style: TextStyle(
                color: AppColors.mediumGrey,
                fontSize: 15.sp,
                height: 23 / 15,
              ),
            ),
          ],
          SizedBox(height: 18.h),
          for (final it in items)
            Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 30.w,
                    child: Text(
                      _s(it, 'num'),
                      style: TextStyle(
                        color: AppColors.mainBlue,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _s(it, 'name'),
                          style: TextStyle(
                            color: AppColors.smoke,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_s(it, 'desc').isNotEmpty) ...[
                          SizedBox(height: 4.h),
                          Text(
                            _s(it, 'desc'),
                            style: TextStyle(
                              color: AppColors.mediumGrey,
                              fontSize: 12.sp,
                              height: 19 / 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          _LinkText(label: s.str('ctaLabel'), href: s.str('ctaHref')),
        ],
      ),
    );
  }
}

/* ── people ─────────────────────────────────────────────────────────── */

/// `label` · `headline` · `items[{name, role, bio, imageSrc}]`
///
/// A sideways run of cards. The last card is deliberately allowed to sit at
/// the screen edge — that peek is what tells a reader there are more.
class _PeopleBlock extends StatelessWidget {
  final PageSection s;
  const _PeopleBlock(this.s);

  @override
  Widget build(BuildContext context) {
    final people = s.list('items');
    if (people.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(_pagePad.w, 32.h, _pagePad.w, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (s.str('label').isNotEmpty) ...[
                SectionLabel(s.str('label')),
                SizedBox(height: 10.h),
              ],
              if (s.str('headline').isNotEmpty)
                Text(
                  s.str('headline'),
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 20.sp,
                    height: 28 / 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        SizedBox(
          height: 210.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: _pagePad.w),
            itemCount: people.length,
            separatorBuilder: (_, __) => SizedBox(width: 12.w),
            itemBuilder: (context, i) {
              final p = people[i];

              return Container(
                width: 150.w,
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(
                    color: AppColors.smoke.withValues(alpha: 0.10),
                    width: 1.5,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Img(_s(p, 'imageSrc'),
                        height: 110.h, width: double.infinity),
                    Padding(
                      padding: EdgeInsets.all(10.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _s(p, 'name'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.smoke,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            _s(p, 'role'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.mainPurple,
                              fontSize: 10.sp,
                            ),
                          ),
                          if (_s(p, 'bio').isNotEmpty) ...[
                            SizedBox(height: 6.h),
                            Text(
                              _s(p, 'bio'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.mediumGrey,
                                fontSize: 10.sp,
                                height: 15 / 10,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/* ── stats ──────────────────────────────────────────────────────────── */

/// `label` · `intro` · `items[{num, label}]`
class _StatsBlock extends StatelessWidget {
  final PageSection s;
  const _StatsBlock(this.s);

  @override
  Widget build(BuildContext context) {
    final items = s.list('items');
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(_pagePad.w, 32.h, _pagePad.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (s.str('label').isNotEmpty) ...[
            SectionLabel(s.str('label')),
            SizedBox(height: 8.h),
          ],
          if (s.str('intro').isNotEmpty) ...[
            Text(
              s.str('intro'),
              style: TextStyle(
                color: AppColors.lightGrey,
                fontSize: 14.sp,
                height: 22 / 14,
              ),
            ),
            SizedBox(height: 18.h),
          ],
          for (final it in items)
            Padding(
              padding: EdgeInsets.only(bottom: 14.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 84.w,
                    child: Text(
                      _s(it, 'num'),
                      style: TextStyle(
                        color: AppColors.mainBlue,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _s(it, 'label'),
                      style: TextStyle(
                        color: AppColors.mediumGrey,
                        fontSize: 12.sp,
                        height: 18 / 12,
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

/* ── cards ──────────────────────────────────────────────────────────── */

/// `items[{imageSrc, label, title, meta}]` — no section label of its own.
class _CardsBlock extends StatelessWidget {
  final PageSection s;
  const _CardsBlock(this.s);

  @override
  Widget build(BuildContext context) {
    final items = s.list('items');
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 28.h),
        SizedBox(
          height: 230.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: _pagePad.w),
            itemCount: items.length,
            separatorBuilder: (_, __) => SizedBox(width: 12.w),
            itemBuilder: (context, i) {
              final it = items[i];

              return Container(
                width: 240.w,
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(
                    color: AppColors.smoke.withValues(alpha: 0.10),
                    width: 1.5,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Img(_s(it, 'imageSrc'),
                        height: 130.h, width: double.infinity),
                    Padding(
                      padding: EdgeInsets.all(12.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_s(it, 'label').isNotEmpty) ...[
                            Text(
                              _s(it, 'label'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.mainPurple,
                                fontSize: 10.sp,
                                letterSpacing: 0.6,
                              ),
                            ),
                            SizedBox(height: 4.h),
                          ],
                          Text(
                            _s(it, 'title'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.smoke,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_s(it, 'meta').isNotEmpty) ...[
                            SizedBox(height: 4.h),
                            Text(
                              _s(it, 'meta'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.mediumGrey,
                                fontSize: 10.sp,
                                height: 15 / 10,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/* ── quote ──────────────────────────────────────────────────────────── */

/// `body` · `attribution` · `imageSrc`
///
/// Note the key is `body`, not `quote` — `quote` is the field name inside
/// `split_prose`. The kinds share a word and not a schema.
class _QuoteBlock extends StatelessWidget {
  final PageSection s;
  const _QuoteBlock(this.s);

  @override
  Widget build(BuildContext context) {
    final body = s.str('body');
    if (body.isEmpty) return const SizedBox.shrink();

    final image = resolveMediaUrl(s.str('imageSrc'));

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          body,
          style: TextStyle(
            color: AppColors.smoke,
            fontSize: 16.sp,
            height: 26 / 16,
            fontStyle: FontStyle.italic,
          ),
        ),
        if (s.str('attribution').isNotEmpty) ...[
          SizedBox(height: 10.h),
          Text(
            '— ${s.str('attribution')}',
            style: TextStyle(color: AppColors.mediumGrey, fontSize: 12.sp),
          ),
        ],
      ],
    );

    return Padding(
      padding: EdgeInsets.only(top: 32.h),
      child: Stack(
        children: [
          if (image.isNotEmpty)
            Positioned.fill(
              child: Opacity(
                opacity: 0.22,
                child: _Img(
                  s.str('imageSrc'),
                  height: double.infinity,
                  width: double.infinity,
                ),
              ),
            ),
          Container(
            width: double.infinity,
            color: image.isEmpty ? AppColors.cardSurface : Colors.transparent,
            padding:
                EdgeInsets.symmetric(horizontal: _pagePad.w, vertical: 28.h),
            child: text,
          ),
        ],
      ),
    );
  }
}

/* ── cta ────────────────────────────────────────────────────────────── */

/// `heading` · `body` · `email` · `buttons[{label, href}]`
///
/// The keys are `heading` and `email` — an earlier draft read `headline` and
/// rendered nothing at all, because a missing key is empty, not an error.
class _CtaBlock extends StatelessWidget {
  final PageSection s;
  const _CtaBlock(this.s);

  @override
  Widget build(BuildContext context) {
    final heading = s.str('heading');
    final body = s.str('body');
    final email = s.str('email');
    final buttons = s.list('buttons');

    if (heading.isEmpty && body.isEmpty && email.isEmpty && buttons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.fromLTRB(_pagePad.w, 32.h, _pagePad.w, 8.h),
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(
          color: AppColors.smoke.withValues(alpha: 0.10),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (heading.isNotEmpty)
            Text(
              heading,
              style: TextStyle(
                color: AppColors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          if (body.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Text(
              body,
              style: TextStyle(
                color: AppColors.mediumGrey,
                fontSize: 13.sp,
                height: 20 / 13,
              ),
            ),
          ],
          if (email.isNotEmpty) ...[
            SizedBox(height: 8.h),
            GestureDetector(
              onTap: () => launchUrl(Uri(scheme: 'mailto', path: email)),
              child: Text(
                email,
                style: TextStyle(
                  color: AppColors.mainBlue,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (buttons.isNotEmpty) ...[
            SizedBox(height: 16.h),
            Wrap(
              spacing: 10.w,
              runSpacing: 10.h,
              children: [
                for (final b in buttons)
                  // A button with nowhere to go is not rendered. The seed ships
                  // "Press Kit" with an empty href on purpose.
                  if (_s(b, 'label').isNotEmpty && _s(b, 'href').isNotEmpty)
                    GestureDetector(
                      onTap: () => _follow(context, _s(b, 'href')),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 18.w,
                          vertical: 10.h,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3.r),
                          border: Border.all(color: AppColors.mainPurple),
                        ),
                        child: Text(
                          _s(b, 'label'),
                          style: TextStyle(
                            color: AppColors.smoke,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
