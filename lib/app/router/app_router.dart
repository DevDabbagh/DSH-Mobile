import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dsh_mobile/layers/auth/presentation/controllers/auth_controller.dart';
import 'package:dsh_mobile/layers/splash/presentation/splash_page.dart';
import 'package:dsh_mobile/layers/onboarding/presentation/onboarding_page.dart';
import 'package:dsh_mobile/layers/auth/presentation/pages/login_page.dart';
import 'package:dsh_mobile/layers/auth/presentation/pages/register_page.dart';
import 'package:dsh_mobile/layers/auth/presentation/pages/otp_page.dart';
import 'package:dsh_mobile/layers/auth/presentation/pages/reset_password_page.dart';

import 'package:dsh_mobile/layers/auth/presentation/pages/forgot_password_page.dart';
import 'package:dsh_mobile/layers/auth/presentation/pages/password_success_page.dart';

import 'package:dsh_mobile/layers/main/presentation/main_navigation_screen.dart';
import 'package:dsh_mobile/layers/home/presentation/home_page.dart';
import 'package:dsh_mobile/layers/read/presentation/read_page.dart';
import 'package:dsh_mobile/layers/films/presentation/films_all_page.dart';
import 'package:dsh_mobile/layers/films/presentation/films_page.dart';
import 'package:dsh_mobile/layers/films/presentation/films_search_page.dart';
import 'package:dsh_mobile/layers/search/presentation/search_page.dart';
import 'package:dsh_mobile/layers/films/presentation/film_details_page.dart';
import 'package:dsh_mobile/layers/events/presentation/events_page.dart';
import 'package:dsh_mobile/layers/about/presentation/about_page.dart';
import 'package:dsh_mobile/layers/support/domain/entities/donation.dart';
import 'package:dsh_mobile/layers/support/presentation/support_page.dart';
import 'package:dsh_mobile/layers/academy/presentation/academy_page.dart';
import 'package:dsh_mobile/layers/discover/presentation/discover_page.dart';
import 'package:dsh_mobile/layers/studio/presentation/studio_all_page.dart';
import 'package:dsh_mobile/layers/studio/presentation/studio_page.dart';
import 'package:dsh_mobile/layers/studio/presentation/studio_search_page.dart';
import 'package:dsh_mobile/layers/studio/presentation/studio_details_page.dart';
import 'package:dsh_mobile/layers/studio/presentation/episode_details_page.dart';
import 'package:dsh_mobile/layers/notifications/presentation/notifications_page.dart';
import 'package:dsh_mobile/layers/profile/presentation/profile_page.dart';

part 'app_router.g.dart';

/// The sign-in flow.
///
/// Reaching one of these while already signed in makes no sense, so the
/// redirect below sends those visits home. Every other route is open: DSH is
/// browsable without an account, exactly as the website is. What needs an
/// account is a handful of *actions* — enrolling in a course, donating,
/// saving something — and those ask at the moment they are taken, via
/// `SignInRequiredDialog`, not by walling off whole screens.
const _authRoutes = {
  '/login',
  '/register',
  '/otp',
  '/forgot_password',
  '/reset_password',
  '/password_success',
};

/// Bridges Riverpod to GoRouter.
///
/// GoRouter re-evaluates `redirect` when this notifies, so signing in or out
/// moves the user without any screen having to navigate explicitly.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    ref.listen(currentUserProvider, (_, __) => notifyListeners());
  }
}

final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorHomeKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellHome');
final shellNavigatorFilmsKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellFilms');
final shellNavigatorAcademyKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellAcademy');
final shellNavigatorStudioKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellStudio');
final shellNavigatorProfileKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellProfile');

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: _AuthRefresh(ref),
    redirect: (context, state) {
      final auth = ref.read(currentUserProvider);
      final path = state.matchedLocation;

      // Session restore is still in flight. Nothing is gated on it any more,
      // but the profile screen would flash its guest state before the
      // restored account appeared, so hold on /splash for the moment it takes.
      if (auth.isLoading) return path == '/splash' ? null : '/splash';

      final signedIn = auth.valueOrNull != null;

      // Signed in but sitting on a sign-in screen — send them home.
      // /reset_password is excluded: a recovery link signs the user in, and
      // bouncing them to Home would leave the password unchanged.
      // /password_success is the confirmation that follows it.
      if (signedIn &&
          _authRoutes.contains(path) &&
          path != '/reset_password' &&
          path != '/password_success') {
        return '/home';
      }

      // Everything else is open. A guest browsing films, studio, episodes or
      // their own profile is the normal case, not an exception.

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) => const OtpPage(),
      ),
      GoRoute(
        path: '/reset_password',
        builder: (context, state) => const ResetPasswordPage(),
      ),
      GoRoute(
        path: '/forgot_password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/password_success',
        builder: (context, state) => const PasswordSuccessPage(),
      ),

      GoRoute(
        path: '/events',
        builder: (context, state) => const EventsPage(),
      ),
      GoRoute(
        path: '/about',
        builder: (context, state) => const AboutPage(),
      ),
      // Support takes the same three query parameters as the website's
      // /support?fundType=…&fundSlug=…&fundTitle=…, so a "Support this
      // project" button anywhere in the app is written the same way it is on
      // the web and the donation carries its project attribution to Stripe.
      // Anything malformed resolves to null — a general donation, never a
      // half-attributed one.
      GoRoute(
        path: '/support',
        builder: (context, state) {
          final q = state.uri.queryParameters;
          return SupportPage(
            target: FundingTarget.fromParams(
              type: q['fundType'],
              slug: q['fundSlug'],
              title: q['fundTitle'],
            ),
          );
        },
      ),
      // Read keeps its own route now that the second tab shows Films, which
      // is what that tab has always been labelled and what the design says it
      // is. Reached from Home rather than the tab bar.
      GoRoute(
        path: '/read',
        builder: (context, state) => const ReadPage(),
      ),
      // Discover moved off the tab bar when Studio took the fourth slot, the
      // one the design assigns it. Still reachable, just not a tab.
      GoRoute(
        path: '/discover',
        builder: (context, state) => const DiscoverPage(),
      ),
      // Outside the shell: a notification tap can arrive from a cold start
      // with no tab selected, and pushing this over whichever tab happens to
      // be showing would leave the bar highlighting something unrelated.
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsPage(),
      ),

      // ── Search ────────────────────────────────────────────────────────
      //
      // All three are OUTSIDE the shell, and that is the point: searching
      // wants the keyboard, the whole height for results, and no tab bar
      // taking the last row of the list and offering a way out of the thing
      // that was just opened.
      //
      // They are separate screens rather than one with a scope parameter
      // because they are not the same screen. `/films/search` and
      // `/studio/search` have facets — stage and form, format and status —
      // and each reads its own tab's filter state, so pressing search on a
      // narrowed tab arrives still narrowed. `/search` has no facets at all,
      // because none of them exist across films, studio work and courses at
      // once; it trades the filters for reach.
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchPage(),
      ),
      // `?filter=1` opens the facet sheet on arrival. The filter button on a
      // tab pushes that rather than dropping a sheet over the tab, so
      // searching and filtering are one screen with one set of chrome instead
      // of two places that look nothing alike.
      GoRoute(
        path: '/films/search',
        builder: (context, state) => FilmsSearchPage(
          openFilter: state.uri.queryParameters['filter'] == '1',
        ),
      ),
      GoRoute(
        path: '/studio/search',
        builder: (context, state) => StudioSearchPage(
          openFilter: state.uri.queryParameters['filter'] == '1',
        ),
      ),
      // Results for the platform-wide search. A screen of its own so the
      // picker stays underneath: going back returns to the query and the
      // sections still chosen, ready to be changed, rather than to a blank
      // field.
      GoRoute(
        path: '/search/results',
        builder: (context, state) => SearchResultsPage(
          request: state.extra as SearchRequest,
        ),
      ),

      // ── Catalogues and detail screens ────────────────────────────────
      //
      // OUTSIDE the shell, and they used to be inside it.
      //
      // Nesting them under their branch kept the Films tab highlighted while
      // you read a film, which sounded right and was wrong twice over:
      //
      //   · the tab bar stayed on screen over every detail page, offering a
      //     way out of the thing you had just opened;
      //   · and — the reason the smearing was so hard to place — the tab
      //     underneath stays MOUNTED in the shell's IndexedStack. Home's hero
      //     carousel and drifting mosaics keep animating behind a pushed
      //     route, repainting under a screen that does not expect to be
      //     repainted. Opening a film from Home is exactly the path that
      //     showed it.
      //
      // Declared before the shell so they win the match: `/films/all` and
      // `/films/search` are listed ahead of `/films/:slug`, because `all` and
      // `search` are legal slugs and a `:slug` declared first would swallow
      // both and go looking for a film by that name.
      GoRoute(
        path: '/films/all',
        builder: (context, state) => const FilmsAllPage(),
      ),
      GoRoute(
        path: '/films/:slug',
        builder: (context, state) => FilmDetailsPage(
          slug: state.pathParameters['slug']!,
        ),
      ),
      GoRoute(
        path: '/studio/all',
        builder: (context, state) => const StudioAllPage(),
      ),
      GoRoute(
        path: '/studio/:slug',
        builder: (context, state) => StudioDetailsPage(
          slug: state.pathParameters['slug']!,
        ),
        routes: [
          // An episode always belongs to a project, so its route nests under
          // one — the page resolves the project first and reads the episode
          // out of it.
          GoRoute(
            path: ':episode',
            builder: (context, state) => EpisodeDetailsPage(
              projectSlug: state.pathParameters['slug']!,
              episodeSlug: state.pathParameters['episode']!,
            ),
          ),
        ],
      ),

      // Bottom Navigation Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainNavigationScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: shellNavigatorHomeKey,
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: HomePage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: shellNavigatorFilmsKey,
            routes: [
              GoRoute(
                path: '/films',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: FilmsPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: shellNavigatorAcademyKey,
            routes: [
              GoRoute(
                path: '/academy',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: AcademyPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: shellNavigatorStudioKey,
            routes: [
              GoRoute(
                path: '/studio',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: StudioPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: shellNavigatorProfileKey,
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ProfilePage(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
