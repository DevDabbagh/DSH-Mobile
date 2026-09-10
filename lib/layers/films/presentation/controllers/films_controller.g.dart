// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'films_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$filmBySlugHash() => r'18b802815870575286765de5c2f3d4a83a01846a';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// One film, by slug.
///
/// Reuses the already-loaded listing when it holds the film, so opening a card
/// shows content immediately instead of a spinner over data the app has.
///
/// Copied from [filmBySlug].
@ProviderFor(filmBySlug)
const filmBySlugProvider = FilmBySlugFamily();

/// One film, by slug.
///
/// Reuses the already-loaded listing when it holds the film, so opening a card
/// shows content immediately instead of a spinner over data the app has.
///
/// Copied from [filmBySlug].
class FilmBySlugFamily extends Family<AsyncValue<Film?>> {
  /// One film, by slug.
  ///
  /// Reuses the already-loaded listing when it holds the film, so opening a card
  /// shows content immediately instead of a spinner over data the app has.
  ///
  /// Copied from [filmBySlug].
  const FilmBySlugFamily();

  /// One film, by slug.
  ///
  /// Reuses the already-loaded listing when it holds the film, so opening a card
  /// shows content immediately instead of a spinner over data the app has.
  ///
  /// Copied from [filmBySlug].
  FilmBySlugProvider call(
    String slug,
  ) {
    return FilmBySlugProvider(
      slug,
    );
  }

  @override
  FilmBySlugProvider getProviderOverride(
    covariant FilmBySlugProvider provider,
  ) {
    return call(
      provider.slug,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'filmBySlugProvider';
}

/// One film, by slug.
///
/// Reuses the already-loaded listing when it holds the film, so opening a card
/// shows content immediately instead of a spinner over data the app has.
///
/// Copied from [filmBySlug].
class FilmBySlugProvider extends AutoDisposeFutureProvider<Film?> {
  /// One film, by slug.
  ///
  /// Reuses the already-loaded listing when it holds the film, so opening a card
  /// shows content immediately instead of a spinner over data the app has.
  ///
  /// Copied from [filmBySlug].
  FilmBySlugProvider(
    String slug,
  ) : this._internal(
          (ref) => filmBySlug(
            ref as FilmBySlugRef,
            slug,
          ),
          from: filmBySlugProvider,
          name: r'filmBySlugProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$filmBySlugHash,
          dependencies: FilmBySlugFamily._dependencies,
          allTransitiveDependencies:
              FilmBySlugFamily._allTransitiveDependencies,
          slug: slug,
        );

  FilmBySlugProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.slug,
  }) : super.internal();

  final String slug;

  @override
  Override overrideWith(
    FutureOr<Film?> Function(FilmBySlugRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FilmBySlugProvider._internal(
        (ref) => create(ref as FilmBySlugRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        slug: slug,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Film?> createElement() {
    return _FilmBySlugProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FilmBySlugProvider && other.slug == slug;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, slug.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FilmBySlugRef on AutoDisposeFutureProviderRef<Film?> {
  /// The parameter `slug` of this provider.
  String get slug;
}

class _FilmBySlugProviderElement extends AutoDisposeFutureProviderElement<Film?>
    with FilmBySlugRef {
  _FilmBySlugProviderElement(super.provider);

  @override
  String get slug => (origin as FilmBySlugProvider).slug;
}

String _$filmsListHash() => r'd551f7eaba4daf176bca8270deb58ac07a52dce9';

/// The Films tab listing.
///
/// A failure is thrown rather than folded away so the screen can offer a
/// retry — unlike onboarding, an empty films list here is a real state
/// ("nothing published yet") and must stay distinguishable from a failure.
///
/// Copied from [FilmsList].
@ProviderFor(FilmsList)
final filmsListProvider = AsyncNotifierProvider<FilmsList, List<Film>>.internal(
  FilmsList.new,
  name: r'filmsListProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$filmsListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$FilmsList = AsyncNotifier<List<Film>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
