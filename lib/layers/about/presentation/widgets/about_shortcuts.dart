import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/config/app_dimensions.dart';
import 'package:dsh_mobile/app/supabase/section_header.dart';
import 'package:dsh_mobile/app/widgets/app_network_image.dart';
import 'package:dsh_mobile/layers/pages/domain/entities/page_section.dart';

/// "What we do" on About — Films, Journalism, Education — as three circular
/// icons that open a card.
///
/// EVERY WORD COMES FROM THE DASHBOARD
///
/// This is not a second list beside the page's own. It **is** the page's
/// `numbered_list` section, drawn as icons instead of as three stacked text
/// blocks. The About page skips that section from its normal rendering and
/// hands it here, so there is exactly one "What we do" on the screen and one
/// place to edit it.
///
/// That also settles the wording. The website's button on the Films item says
/// "Explore Films"; on Academy it says "Visit Academy". Those strings are
/// `linkLabel` on the very rows the website reads, so the dialog says what the
/// site says without anyone keeping two lists in step — which is precisely
/// what Ahmed asked for, and why the labels are not in the ARB.
///
/// WHAT IS *NOT* FROM THE DASHBOARD
///
/// The icon and the picture. `numbered_list` has no field for either, and the
/// three items are stable — Films, Journalism, Education — so the icon is
/// chosen from `linkHref`: the route is the one thing in the row that says
/// what the item actually is. A row pointing somewhere unexpected gets a
/// neutral glyph rather than a wrong one.
///
/// The picture is real DSH work pulled from the header pools the dashboard
/// already fills, so the card is illustrated by the thing it is describing.
class AboutShortcutRow extends StatelessWidget {
  /// The page's `numbered_list` section. Its `label` is the heading.
  final PageSection section;

  const AboutShortcutRow({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    final label = section.str('label');
    final items = section.list('items');

    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.pagePadding.w,
        32.h,
        AppDimensions.pagePadding.w,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) ...[
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: AppColors.mediumGrey,
                fontSize: 11.sp,
                letterSpacing: 1.8,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 18.h),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final item in items) Expanded(child: _Shortcut(item: item)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Chosen from the route, not stored. See the class comment above.
IconData _iconFor(String href) {
  switch (href) {
    case '/films':
      return Icons.movie_outlined;
    case '/read':
      return Icons.menu_book_outlined;
    case '/academy':
      return Icons.school_outlined;
    case '/studio':
      return Icons.podcasts_outlined;
    case '/discover':
      return Icons.public_outlined;
    default:
      return Icons.arrow_forward;
  }
}

/// The routes that ARE tabs — `go` switches the shell to them; everything
/// else is pushed so it keeps a back button to About.
const _tabRoots = {'/home', '/films', '/academy', '/studio', '/profile'};

String _text(Map<String, dynamic> item, String key) {
  final v = item[key];
  return v is String ? v : '';
}

class _Shortcut extends StatelessWidget {
  final Map<String, dynamic> item;

  const _Shortcut({required this.item});

  @override
  Widget build(BuildContext context) {
    final title = _text(item, 'title');

    return GestureDetector(
      // The card first, always. Tapping straight through to Films would make
      // this a navigation bar with three buttons on it; the point of the row
      // is that each of these is a thing DSH does, and the sentence explaining
      // it is already written on this page.
      onTap: () => AboutShortcutSheet.show(context, item),
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            width: 52.w,
            height: 52.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cardSurface.withValues(alpha: 0.88),
              border: Border.all(
                color: AppColors.smoke.withValues(alpha: 0.10),
                width: 0.8,
              ),
            ),
            child: Icon(
              _iconFor(_text(item, 'linkHref')),
              color: AppColors.smoke,
              size: 22.w,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.smoke,
              fontSize: 12.sp,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Picture, title, the paragraph, and the button the website uses.
///
/// A bottom sheet rather than an `AlertDialog`: it can be swiped away, it
/// leaves the page visible behind it, and it is the same gesture Studio's
/// capability card already taught on the tab next door.
class AboutShortcutSheet extends ConsumerWidget {
  final Map<String, dynamic> item;

  const AboutShortcutSheet({super.key, required this.item});

  static Future<void> show(BuildContext context, Map<String, dynamic> item) {
    return showModalBottomSheet<void>(
      context: context,
      // The root navigator, so the sheet covers the floating tab bar
      // instead of sliding up underneath it — the bar is drawn by the
      // shell, which owns the branch navigator a modal would otherwise
      // mount inside.
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AboutShortcutSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = _text(item, 'title');
    final desc = _text(item, 'desc');
    final linkLabel = _text(item, 'linkLabel');
    final href = _text(item, 'linkHref');

    final image = _illustration(ref, href);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.deepBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(14.r)),
        border: Border(
          top: BorderSide(color: AppColors.smoke.withValues(alpha: 0.10)),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nothing at all rather than a grey rectangle when there is no
            // published work in that section yet. An empty placeholder is a
            // picture of nothing.
            if (image.isNotEmpty)
              SizedBox(
                height: 170.h,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppNetworkImage(url: image, fit: BoxFit.cover),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.deepBackground.withValues(alpha: 0.85),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppDimensions.pagePadding.w,
                image.isEmpty ? 26.h : 18.h,
                AppDimensions.pagePadding.w,
                20.h,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 20.sp,
                      height: 1.25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (desc.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    Text(
                      desc,
                      style: TextStyle(
                        color: AppColors.lightGrey,
                        fontSize: 13.sp,
                        height: 20 / 13,
                      ),
                    ),
                  ],
                  // No button when the editor left the row without one. A
                  // button labelled with an empty string is worse than none.
                  if (linkLabel.isNotEmpty && href.isNotEmpty) ...[
                    SizedBox(height: 20.h),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        _tabRoots.contains(href)
                            ? context.go(href)
                            : context.push(href);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              linkLabel,
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Icon(
                              Icons.arrow_forward,
                              color: AppColors.white,
                              size: 16.w,
                            ),
                          ],
                        ),
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

  /// A cover from the section this item points at, so the card is illustrated
  /// by DSH's own work rather than a bundled stock image.
  ///
  /// Read has no content table yet, so it borrows a film — the journalism and
  /// the films come out of the same field work.
  String _illustration(WidgetRef ref, String href) {
    final pools = ref.watch(headerImagePoolsProvider);

    List<String> pick(HeaderSource source) =>
        (pools[source] ?? const <String>[]).where((u) => u.isNotEmpty).toList();

    final candidates = switch (href) {
      '/academy' => [
          ...pick(HeaderSource.academy),
          ...pick(HeaderSource.films)
        ],
      '/studio' => [...pick(HeaderSource.studio), ...pick(HeaderSource.films)],
      _ => [...pick(HeaderSource.films), ...pick(HeaderSource.studio)],
    };

    return candidates.isEmpty ? '' : candidates.first;
  }
}
