// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$onboardingSlidesHash() => r'83fa938067bdf3f0498c8c75d32e3317329430e4';

/// The slides themselves.
///
/// A failed fetch resolves to an EMPTY list rather than an error: onboarding
/// is not a gate. If the slides can't be loaded the app opens on Home, and
/// the reader never learns anything went wrong.
///
/// Copied from [OnboardingSlides].
@ProviderFor(OnboardingSlides)
final onboardingSlidesProvider = AutoDisposeAsyncNotifierProvider<
    OnboardingSlides, List<OnboardingSlide>>.internal(
  OnboardingSlides.new,
  name: r'onboardingSlidesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$onboardingSlidesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$OnboardingSlides = AutoDisposeAsyncNotifier<List<OnboardingSlide>>;
String _$onboardingControllerHash() =>
    r'740e6220107ff0307a0caf582415a4b9122e6ab2';

/// Marking onboarding as seen.
///
/// Copied from [OnboardingController].
@ProviderFor(OnboardingController)
final onboardingControllerProvider =
    AutoDisposeAsyncNotifierProvider<OnboardingController, void>.internal(
  OnboardingController.new,
  name: r'onboardingControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$onboardingControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$OnboardingController = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
