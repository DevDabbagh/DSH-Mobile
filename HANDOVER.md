# DSH Mobile — Development Handover

## Project Overview

**Don't Skip Humanity (DSH)** is a cinematic/editorial ecosystem — not a streaming service. The mobile app serves as the companion experience for films, studio content, academy courses, articles, and impact initiatives.

**Package name:** `dsh_mobile`
**Org:** `com.dontskiphumanity`
**Min SDK:** Dart >=3.0.0, Flutter 3.0+

---

## Architecture

Strict **Clean Architecture** with feature-based organization. Two top-level domains under `lib/`:

### `app/` — Global Configuration & Core Logic

```
app/
├── config/
│   ├── app_colors.dart         # Brand palette (black/gold/cream cinematic theme)
│   ├── app_dimensions.dart     # Spacing & sizing tokens
│   └── constants.dart          # API base URL, SharedPrefs keys, timeouts
├── core/
│   ├── errors/
│   │   ├── exceptions.dart     # ServerException, CacheException
│   │   └── failures.dart       # Failure base (Equatable), ServerFailure, CacheFailure, NetworkFailure
│   └── usecases/
│       └── usecase.dart        # Abstract UseCase<Type, Params> with Dartz Either, NoParams
├── network/
│   ├── dio_provider.dart       # Riverpod Dio provider with auth interceptor, 401 handling
│   ├── dio_exceptions.dart     # DioException → human-readable error messages + snackbar
│   └── base_response_model.dart # Generic BaseResponseModel<T> (JsonSerializable)
├── router/
│   └── app_router.dart         # GoRouter setup, navigatorKey, splash → home routes
├── theme/
│   └── app_theme.dart          # Light + Dark ThemeData as Riverpod providers (dark-first)
├── providers/
│   ├── shared_prefs_helper.dart # SharedPreferences wrapper (token, user, locale, onboarding)
│   └── shared_prefs_provider.dart # Riverpod provider (overridden in main.dart)
├── utils/
│   ├── ui_helpers.dart         # Success/error/warning snackbar helpers
│   └── validation_extensions.dart # Email, phone, password, required validators
└── widgets/
    ├── custom_button.dart      # ElevatedButton with loading state, icon support
    ├── loader.dart             # Centered CircularProgressIndicator
    ├── error_retry_widget.dart # Error state with retry button
    ├── empty_state_widget.dart # Icon + title + optional action
    ├── section_header.dart     # Title + "See All" link
    └── loading_overlay.dart    # Non-dismissible loading dialog (static show/hide)
```

### `layers/` — Feature-Based Clean Architecture

Each feature follows this pattern:

```
layers/
└── [feature_name]/
    ├── domain/                 # PURE DART — no UI, no JSON
    │   ├── entities/           # Business objects (Equatable)
    │   └── repositories/       # Abstract contracts only
    ├── data/                   # IMPLEMENTATION
    │   ├── models/             # Extend entities, add fromJson/toJson
    │   ├── datasources/        # Retrofit @RestApi() abstract classes
    │   └── repositories/       # Implement domain contracts, return Either<Failure, T>
    └── presentation/           # UI & STATE
        ├── controllers/        # Riverpod @riverpod AsyncNotifiers
        └── [feature]_page.dart # Widget
```

---

## Current Features (Completed)

### 1. Splash Screen (`layers/splash/`)
- **File:** `presentation/splash_page.dart`
- Animated fade+scale logo reveal on dark background
- DSH text branding ("DON'T SKIP" / "HUMANITY" in white/gold)
- Tagline: "Stories that move us forward"
- Auto-navigates to `/home` after 2.5s delay
- **TODO:** Replace navigation with auth check once auth feature is built. The GoRouter redirect pattern from MontCamp is ready to plug in — just add an `authNotifierProvider` and the redirect callback in `app_router.dart`.

### 2. Home Screen (`layers/home/`)
- **Full clean architecture:** entities → repository interface → mock impl → controller → page
- **Domain entities:** `FeaturedContent`, `HomeSection`
- **Repository:** `HomeRepositoryImpl` with mock data (placeholder images from picsum.photos)
- **Controller:** `HomeController` (Riverpod AsyncNotifier) with refresh support
- **UI components:**
  - `_FeaturedCarousel` — Hero PageView with gradient overlay, type badges, dot indicators
  - `_VerticalCardSection` — Horizontal scroll of poster-style film cards
  - `_HorizontalCardSection` — Horizontal scroll of article cards (image + text side by side)
  - `_HomeShimmer` — Skeleton loading placeholder
- Pull-to-refresh via `RefreshIndicator`
- SliverAppBar with DSH logo, search and profile icons

---

## Tech Stack

| Concern | Library | Version |
|---|---|---|
| State Management | flutter_riverpod + riverpod_annotation + riverpod_generator | ^2.5.1 |
| Navigation | go_router | ^14.0.0 |
| Networking | dio + retrofit | ^5.4.0 / >=4.6.0 |
| JSON Parsing | json_serializable + json_annotation | ^6.7.1 |
| Functional Utils | dartz (Either<L, R>) | ^0.10.1 |
| Immutable Models | freezed + freezed_annotation | ^2.5.7 |
| UI Sizing | flutter_screenutil (design: 428x926) | ^5.9.0 |
| Images | cached_network_image | ^3.3.1 |
| Assets Codegen | flutter_gen_runner | ^5.4.0 |
| Localization | flutter_localizations + ARB files (en/ar) | built-in |

---

## Key Patterns to Follow

### Adding a New Feature

1. **Domain first** — create entity in `domain/entities/`, repository interface in `domain/repositories/`
2. **Data layer** — create model (extends entity + `fromJson`), Retrofit datasource, repository impl that catches exceptions and returns `Either<Failure, T>`
3. **Presentation** — create controller (`@riverpod class XController extends _$XController`), page widget using `ref.watch()` with `.when(data:, loading:, error:)`
4. **Route** — add `GoRoute` in `app/router/app_router.dart`
5. **Run codegen** — `dart run build_runner build --delete-conflicting-outputs`

### Provider Chain (DI via Riverpod)

```
dioProvider → featureRemoteDataSourceProvider → featureRepositoryProvider → featureControllerProvider
```

No get_it. No service locators. Riverpod handles everything.

### Error Handling

```dart
// In repository impl:
try {
  final response = await dataSource.getData();
  return Right(response);
} on DioException catch (e) {
  return Left(ServerFailure(e.message ?? 'Server error'));
} catch (e) {
  return Left(ServerFailure('Unexpected error'));
}

// In controller:
result.fold(
  (failure) => state = AsyncError(failure.message, StackTrace.current),
  (data) => state = AsyncData(data),
);
```

### UI Rules

- **Colors:** always use `AppColors.xxx` — never hardcode hex
- **Sizing:** use `.w`, `.h`, `.sp`, `.r` from ScreenUtil
- **Text:** use `Theme.of(context).textTheme.xxx`
- **Assets:** after adding to `assets/images/`, run build_runner → use `Assets.images.xxx.image()`
- **Theme:** dark-first for DSH (cinematic brand)

---

## What Needs to Be Built Next

### Immediate (Phase 1)

1. **Auth Feature** (`layers/auth/`)
   - Login/register pages
   - AuthNotifier (keepAlive provider) for session state
   - GoRouter redirect logic (pattern exists in MontCamp — copy and adapt)
   - Token persistence via SharedPrefsHelper (already has `saveToken`/`getToken`)

2. **Onboarding Feature** (`layers/onboarding/`)
   - 3-4 screen walkthrough introducing DSH
   - Track `hasSeenOnboarding` via SharedPrefsHelper (already has the method)

3. **Bottom Navigation Shell**
   - `IndexedStack` with tabs: Home, Films, Studio, Academy, Profile
   - `StateProvider<int>` for active tab index (same pattern as MontCamp)

4. **Films Feature** (`layers/films/`)
   - Film listing page
   - Film detail page (not full playback — DSH is editorial, not streaming)
   - Domain: `Film` entity, `FilmsRepository`

5. **Replace Mock Data** in HomeRepositoryImpl with real API calls via Retrofit datasource

### Future (Phase 2-3)

- Academy feature (courses, workshops)
- Studio / Articles feature
- Impact section
- Profile / Settings
- Push notifications (Firebase FCM)
- Localization toggle (en/ar infrastructure is already in place)

---

## Setup Instructions

```bash
cd "DSH Mobile"

# 1. Generate platform folders (android/ios) — won't overwrite lib/
flutter create . --project-name dsh_mobile --org com.dontskiphumanity

# 2. Install dependencies
flutter pub get

# 3. Generate .g.dart files (Riverpod, Retrofit, JSON, Assets)
dart run build_runner build --delete-conflicting-outputs

# 4. Add a logo image to assets/images/ (ic_logo.png, ic_logo_splash.png, app_icon.png)
# Then regenerate:
dart run build_runner build --delete-conflicting-outputs
dart run flutter_native_splash:create

# 5. Run
flutter run
```

---

## Brand Reference

- **Primary:** Gold `#D4A84B` — accent, CTAs, highlights
- **Background:** Near-black `#0A0A0A` — cinematic dark theme
- **Surface:** Dark grey `#1A1A1A` — cards, inputs
- **Text:** White `#FAFAFA` on dark, grey `#B0B0B0` for secondary
- **Cream:** `#F5F0E8` — editorial warmth where needed
- **Voice:** Premium, cinematic, editorial. Not a streaming service — a transnational media company.

---

## Reference Projects

- **MontCamp** (`/Users/ahmed/4Me/2026 Projects/MontClub/Mont Camp`) — same architecture, more mature. Good reference for auth flow, bottom nav, shimmer patterns, Retrofit datasources, biometric login.
- **Template** (`github.com/DevDabbagh/Flutter-Riverpod-Clean-Architecture-Template`) — the canonical folder structure this project follows.
- **DSH Website** (`dsh-landing/`, `dsh-admin/`) — the web counterparts in the same parent folder.
