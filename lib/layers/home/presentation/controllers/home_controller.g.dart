// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$heroSlidesHash() => r'f1511350aad417bb4f348310ac367969476f739e';

/// The header slider, shared with the website.
///
/// Its own provider rather than a field on the layout: the slider is one row
/// in a different table (`landing_page_config`), written by a different
/// editor, and a failure to read it must not take the whole Home screen down
/// with it — the carousel simply does not render.
///
/// Copied from [heroSlides].
@ProviderFor(heroSlides)
final heroSlidesProvider = FutureProvider<List<HeroSlide>>.internal(
  heroSlides,
  name: r'heroSlidesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$heroSlidesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HeroSlidesRef = FutureProviderRef<List<HeroSlide>>;
String _$homeControllerHash() => r'afa1dab25c338876fa23213641966b844124f6bb';

/// The Home screen's layout.
///
/// keepAlive: Home is the tab people leave and return to most, and it is the
/// most expensive screen to rebuild. Without it, every trip into a film and
/// back re-queried the layout and re-rendered every card from its shimmer,
/// which read as the app reloading itself.
///
/// Copied from [HomeController].
@ProviderFor(HomeController)
final homeControllerProvider =
    AsyncNotifierProvider<HomeController, List<HomeSection>>.internal(
  HomeController.new,
  name: r'homeControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$homeControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$HomeController = AsyncNotifier<List<HomeSection>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
