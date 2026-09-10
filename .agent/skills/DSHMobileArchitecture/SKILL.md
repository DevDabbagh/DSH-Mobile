---
name: DSH Mobile Clean Architecture
description: Strict guidelines for organizing the Domain, Data, and Presentation layers in the Don't Skip Humanity (DSH) Mobile application. Covers Supabase data access, feature-first folders, and the Either error type.
---

# DSH Mobile Clean Architecture

When asked to build a feature, respect the following strict structure.

## 0. Folder Layout — FEATURE-FIRST ✅

Every feature owns all three of its layers. **NEVER** split by layer at the top level.

```
lib/layers/{feature}/
├── domain/
│   ├── entities/{entity}.dart
│   └── repositories/{feature}_repository.dart
├── data/
│   ├── models/{entity}_model.dart
│   ├── datasources/{feature}_remote_datasource.dart
│   └── repositories/{feature}_repository_impl.dart
└── presentation/
    ├── controllers/{feature}_controller.dart
    ├── widgets/
    └── {feature}_page.dart
```

- ✅ `lib/layers/home/domain/entities/home_section.dart`
- ❌ `lib/layers/domain/home/home_section.dart`

App-wide code lives outside `layers/`, in `lib/app/`:
`config/` · `core/errors/` · `core/usecases/` · `network/` · `supabase/` · `router/` · `theme/` · `providers/` · `utils/` · `widgets/`

## 1. Domain Layer

Pure Dart. No Flutter imports, no JSON, no Supabase.

### Entities (`domain/entities/`)
Plain classes extending `Equatable`. **NEVER** put `fromJson` here — that belongs to the model.

### Repository Contracts (`domain/repositories/`)
Abstract classes only. **ALWAYS** return `Future<Either<Failure, T>>` from `dartz`.

```dart
abstract class FilmsRepository {
  Future<Either<Failure, List<Film>>> getFilms();
  Future<Either<Failure, Film>> getFilmBySlug(String slug);
}
```

For operations with no meaningful return value, use `Either<Failure, Unit>` (`dartz`'s `unit`) — **NOT** `void`.

See `examples/example_repository.dart`.

## 2. Data Layer

### Models (`data/models/`)
- **ALWAYS** use `freezed` + `json_annotation`.
- **ALWAYS** map Supabase `snake_case` columns with `@JsonKey(name: '...')`.
- Multilingual JSONB columns arrive as `Map<String, dynamic>`. Resolve them with `pickLang()` from `lib/app/supabase/lang_helper.dart` — **NEVER** read `['en']` directly, that ignores the user's language.
- **NEVER** duplicate a model. If an entity is shared, define it once and import it.
- Models extend their domain entity, or expose a `toEntity()`.

See `examples/example_model.dart`.

### Remote Datasources (`data/datasources/`)

**Supabase is the default for every DSH content table.** Dio + Retrofit are reserved for third-party APIs (Stripe, etc.) — do not use them for Supabase.

- Take a `SupabaseClient` in the constructor, provided via `supabaseClientProvider`.
- Return the raw shape (`List<Map<String, dynamic>>` / `Map<String, dynamic>`). Parsing into models is the repository's job.
- Let `PostgrestException` propagate — the repository catches it.
- There is **no `BaseResponseModel`** on the Supabase path. Supabase returns rows directly; a response envelope would be dead weight.

See `examples/example_remote_datasource.dart`.

### Repository Implementations (`data/repositories/`)
- Catch `PostgrestException` and map it via `SupabaseExceptions.toFailure(e)`, then `Left(failure)`.
- Catch generic `catch (e)` as a final safety net — a parsing bug must not crash the app.
- Return `Right(data)` on success.
- Provide via a `@riverpod` function returning the **abstract** repository type.
- **ALWAYS** use the generic `Ref` type for provider arguments. Do NOT use generated `XxxRef` types.

```dart
@riverpod
FilmsRepository filmsRepository(Ref ref) =>
    FilmsRepositoryImpl(ref.read(filmsRemoteDataSourceProvider));
```

See `examples/example_repository_impl.dart` for the full pattern.

### Honouring the Data Switcher
The dashboard exposes a per-module `mock | live` setting in `site_settings.data_source`. Repositories for content modules (films, studio, academy, articles, events, impact) **MUST** consult `dataSourceServiceProvider` and fall back to mock data when the module is set to `mock` or when a live query returns empty. This mirrors `lib/api.ts` on the web, so the dashboard toggle governs both surfaces.

## 3. Presentation Layer
- **Controllers / ViewModels**: see the `DSH Mobile Riverpod State` skill.
- **UI Pages & Widgets**: see the `DSH Mobile UI & Widgets` skill.
- Page files **MUST** stay under ~400 lines. Extract sections into `presentation/widgets/`.

## 4. Error Handling

`lib/app/core/errors/failures.dart` defines `Failure` (Equatable) with `ServerFailure`, `CacheFailure`, `NetworkFailure`.

Repositories return `Left(Failure)`. Controllers unwrap with `fold()` and set `AsyncError`. UI never sees a `Failure` object directly — it reads `AsyncValue.error`.
