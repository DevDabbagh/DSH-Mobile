---
name: DSH Mobile Riverpod State
description: Strict guidelines for creating AsyncNotifier ViewModels, unwrapping Either results, and linking state to UI in the Don't Skip Humanity (DSH) Mobile application.
---

# DSH Mobile Riverpod State Management

When asked to link screens with ViewModels or state, you **MUST** strictly use Riverpod `AsyncNotifier` structures. Do **NOT** use the legacy `StateNotifier`.

## 1. The AsyncNotifier (ViewModel)

Create `presentation/controllers/<feature>_controller.dart`. Never wrap `AsyncValue` manually. Return `FutureOr<T>` from `build()`.

**ALWAYS** use the generic `Ref` type in provider functions — never the generated `XxxRef` types.

## 2. Unwrapping `Either` ✅ MANDATORY

Repositories return `Either<Failure, T>` (dartz). The controller is where it becomes `AsyncValue`.

**In `build()`** — throw on the Left so Riverpod maps it to `AsyncError` naturally:
```dart
@override
FutureOr<List<Film>> build() async {
  final result = await ref.read(filmsRepositoryProvider).getFilms();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (films) => films,
  );
}
```

**In a mutation or refresh** — set state directly from the fold:
```dart
Future<void> refresh() async {
  state = const AsyncLoading<List<Film>>().copyWithPrevious(state);
  final result = await ref.read(filmsRepositoryProvider).getFilms();
  state = result.fold(
    (failure) => AsyncError(failure.message, StackTrace.current),
    (films) => AsyncData(films),
  );
}
```

**NEVER** let a `Failure` object reach the UI. The UI reads `AsyncValue.error` only.

See `examples/example_async_notifier.dart`.

## 3. Preserving Data While Reloading

For refresh and pagination, **ALWAYS** use `copyWithPrevious` so the screen keeps showing content instead of flashing back to a shimmer:
```dart
state = const AsyncLoading<T>().copyWithPrevious(state);
```
Use a bare `const AsyncLoading()` only when there is genuinely nothing to keep.

## 4. Linking the UI: Initial Page Load (Shimmer)

Use `.when()` to map the async states. The `loading:` state **MUST** render a `Shimmer` skeleton mirroring the screen layout — never a plain `CircularProgressIndicator`.

The `error:` state **MUST** render `ErrorRetryWidget` with a working retry that calls `ref.invalidate(...)` — never a bare `Text(error.toString())`.

```dart
filmsState.when(
  data: (films) => _buildContent(films),
  loading: () => const FilmsShimmer(),
  error: (err, _) => ErrorRetryWidget(
    message: err.toString(),
    onRetry: () => ref.invalidate(filmsControllerProvider),
  ),
)
```

## 5. Wire the UI to the DATA ⚠️

```dart
data: (films) => _buildContent(films),   // ✅
data: (_) => _buildContent(),            // ❌ discards what was fetched
```

Discarding the value with `_` while the widget renders hardcoded content makes the whole architecture decorative. If a screen shows placeholder content, that is unfinished work — not a pattern to copy.

## 6. Mutations with Loading Overlay ✅ STANDARD PATTERN

When submitting data (login, form post, create, delete), use `ref.listen` to drive a `LoadingOverlay`. This is **MANDATORY**.

```dart
ref.listen(featureControllerProvider, (previous, next) {
  if (next.isLoading && !(previous?.isLoading ?? false)) {
    LoadingOverlay.show(context);
  }
  if (previous?.isLoading == true && !next.isLoading) {
    LoadingOverlay.hide(context);
  }
  if (next.hasError) {
    UIHelpers.showErrorSnackBar(context, next.error.toString());
  }
});
```

## 7. Mutation Error-Handling ✅ MANDATORY

Use `try/catch` to set state. **NEVER** set `AsyncValue.error` manually with `StackTrace.current` **and then** rethrow — that fires the error handling twice.

See `examples/example_async_notifier.dart` for the correct pattern.

## 8. Polling

For endpoints re-fetched on a timer, use `Timer.periodic` inside `build()` with `ref.onDispose` to cancel it.

See `examples/example_polling_notifier.dart`.

## 9. Locale-Dependent Providers

Content is multilingual. Any repository provider that resolves text **MUST** `ref.watch(localeControllerProvider)` so switching language rebuilds it and refetches in the new language. Using `ref.read` there leaves stale text on screen after a language change.
