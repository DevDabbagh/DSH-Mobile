import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dsh_mobile/app/providers/shared_prefs_provider.dart';
import 'package:dsh_mobile/layers/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:dsh_mobile/layers/onboarding/domain/entities/onboarding_slide.dart';

part 'onboarding_controller.g.dart';

/// The slides themselves.
///
/// A failed fetch resolves to an EMPTY list rather than an error: onboarding
/// is not a gate. If the slides can't be loaded the app opens on Home, and
/// the reader never learns anything went wrong.
@riverpod
class OnboardingSlides extends _$OnboardingSlides {
  @override
  FutureOr<List<OnboardingSlide>> build() async {
    final result = await ref.read(onboardingRepositoryProvider).getSlides();
    return result.fold((_) => const <OnboardingSlide>[], (slides) => slides);
  }

  /// Retry after a failed load — bound to the retry button.
  Future<void> refresh() async {
    state = const AsyncLoading<List<OnboardingSlide>>().copyWithPrevious(state);

    final result = await ref.read(onboardingRepositoryProvider).getSlides();
    state = result.fold(
      (failure) => AsyncError(failure.message, StackTrace.current),
      (slides) => AsyncData(slides),
    );
  }
}

/// Marking onboarding as seen.
@riverpod
class OnboardingController extends _$OnboardingController {
  @override
  FutureOr<void> build() {}

  Future<void> completeOnboarding() async {
    state = const AsyncLoading();
    try {
      await ref.read(sharedPrefsHelperProvider).setHasSeenOnboarding(true);
      state = const AsyncData(null);
    } catch (e, stack) {
      state = AsyncError(e.toString(), stack);
    }
  }
}
