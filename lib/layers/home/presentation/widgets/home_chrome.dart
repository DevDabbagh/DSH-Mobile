import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:dsh_mobile/app/config/app_colors.dart';
import 'package:dsh_mobile/app/config/app_dimensions.dart';
import 'package:dsh_mobile/l10n/app_localizations.dart';

/// The pieces every Home section shares.
///
/// They were private methods on the 1393-line `_HomePageState`, which meant a
/// section could not be moved, reordered or tested without carrying the whole
/// screen with it.

/// The five routes that ARE tabs, rather than screens reached from one.
///
/// Kept beside [goToRoute] because the two only make sense together.
const _tabRoots = {'/home', '/films', '/academy', '/studio', '/profile'};

/// Navigate somewhere the app can reach, choosing `go` or `push` correctly.
///
/// `push` stacks a screen on the branch you are already in, so pushing
/// `/films` from Home opened the Films tab's content with the tab bar still
/// highlighting Home — every "See all" on this screen did that. `go` switches
/// the shell to that branch, which is what selecting a tab means.
///
/// Anything that is not a tab — `/support`, `/read`, `/notifications`, a
/// film's detail page — is still pushed, so it keeps a back button and
/// returns you to Home where you left off.
void goToRoute(BuildContext context, String route) {
  if (route.isEmpty) return;
  if (_tabRoots.contains(route)) {
    context.go(route);
  } else {
    context.push(route);
  }
}

/// Wraps a section's content with the standard gap beneath it — and
/// collapses to nothing at all when the section has nothing to show.
///
/// The gap has to belong to the section rather than sit between siblings in
/// the parent. Several sections render nothing when their source is empty: a
/// rail with no published films, an impact strip with no figures. A
/// separator interleaved by the parent would leave 32 pixels of nothing
/// where the section would have been, and three empty rails would open a
/// hole the height of a thumbnail.
/// [gap] overrides the standard 32 for the few places the design pulls two
/// sections together — the search field sits close under the carousel, and
/// the shortcut row close over the first rail, because in both cases the pair
/// reads as one unit rather than two.
Widget homeSection({
  required bool visible,
  required Widget child,
  double gap = 32,
}) {
  if (!visible) return const SizedBox.shrink();
  return Padding(
    padding: EdgeInsets.only(bottom: gap.h),
    child: child,
  );
}

/// The tighter gap, for sections the design groups with the one beneath.
const double kHomeTightGap = 14;

/// Narrows a rail's live rows down to what the editor chose.
///
/// [all] is always the live list — published rows, read this second. [picks]
/// only decides which of them appear and in what order.
///
/// Two properties follow from that, and both matter:
///
///   · a picked item that is no longer published simply is not in [all], so
///     it drops out of the rail by itself. Nobody has to remember to come
///     back and unpick it.
///   · an unpicked rail is not an empty rail. Empty picks mean "not curated",
///     and the rail shows the newest [limit] — the behaviour every rail had
///     before picking existed, and the one a new rail should start with.
///
/// [limit] still caps a curated rail too: if someone picks eight and the
/// dashboard's maximum later drops to five, the reader sees five rather than
/// a row that quietly outgrew its design.
List<T> railItems<T>(
  List<T> all,
  List<String> picks,
  int limit,
  String Function(T) slugOf,
) {
  if (picks.isEmpty) return all.take(limit).toList();

  final bySlug = {for (final item in all) slugOf(item): item};

  return picks.map((slug) => bySlug[slug]).whereType<T>().take(limit).toList();
}

/// Cards on Home sit on photographs, and a card on a photograph needs a
/// shadow to separate from it.
BoxShadow homeCardShadow() => BoxShadow(
      color: Colors.black.withValues(alpha: 0.8),
      blurRadius: 15,
      spreadRadius: 2,
      offset: const Offset(0, 8),
    );

/// Home's stills are desaturated and lifted, so the screen reads as one
/// surface rather than a wall of competing photographs.
///
/// Superseded by `ColorizeOnScroll`, which starts here and animates towards
/// colour as the image is scrolled up — the website's behaviour, which this
/// constant only ever imitated at rest. Kept as the reference for the resting
/// state; nothing renders it directly any more.
const ColorFilter kHomeLightGrayscale = ColorFilter.matrix([
  0.33, 0.59, 0.11, 0, -20, //
  0.33, 0.59, 0.11, 0, -20, //
  0.33, 0.59, 0.11, 0, -20, //
  0, 0, 0, 1, 0, //
]);

/// A section heading, with an optional "See all" that actually goes
/// somewhere.
///
/// The old version drew the "See all" row with no `onTap` at all — it looked
/// like a link on every rail and did nothing on any of them.
class HomeSectionTitle extends StatelessWidget {
  final String title;
  final String viewAllRoute;

  const HomeSectionTitle({
    super.key,
    required this.title,
    this.viewAllRoute = '',
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppDimensions.pagePadding.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: AppColors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (viewAllRoute.isNotEmpty)
            GestureDetector(
              onTap: () => goToRoute(context, viewAllRoute),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Text(
                    l10n.seeAll,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12.sp,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.arrow_forward,
                    color: AppColors.textMuted,
                    size: 14.w,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
