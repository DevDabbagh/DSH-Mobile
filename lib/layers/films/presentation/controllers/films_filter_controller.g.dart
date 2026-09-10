// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'films_filter_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$filmsFilterControllerHash() =>
    r'91a1d07aa1ddbca2c0800a239673e31839b1f877';

/// Deliberately NOT keepAlive.
///
/// The content lists are cached for the life of the app because refetching
/// them is expensive; a filter is the opposite — it is the reader's current
/// question, and it should not still be applied when they come back to Films
/// an hour later wondering where half the library went.
///
/// Copied from [FilmsFilterController].
@ProviderFor(FilmsFilterController)
final filmsFilterControllerProvider =
    AutoDisposeNotifierProvider<FilmsFilterController, FilmsFilter>.internal(
  FilmsFilterController.new,
  name: r'filmsFilterControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$filmsFilterControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$FilmsFilterController = AutoDisposeNotifier<FilmsFilter>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
