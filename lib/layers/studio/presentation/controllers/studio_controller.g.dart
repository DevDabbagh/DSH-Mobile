// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'studio_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$studioProjectBySlugHash() =>
    r'ea703b0543ec7b5d3a552e4b118e8f80c498461f';

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

/// One project with its episodes, by slug — served from the listing when it is
/// already loaded.
///
/// Copied from [studioProjectBySlug].
@ProviderFor(studioProjectBySlug)
const studioProjectBySlugProvider = StudioProjectBySlugFamily();

/// One project with its episodes, by slug — served from the listing when it is
/// already loaded.
///
/// Copied from [studioProjectBySlug].
class StudioProjectBySlugFamily extends Family<AsyncValue<StudioProject?>> {
  /// One project with its episodes, by slug — served from the listing when it is
  /// already loaded.
  ///
  /// Copied from [studioProjectBySlug].
  const StudioProjectBySlugFamily();

  /// One project with its episodes, by slug — served from the listing when it is
  /// already loaded.
  ///
  /// Copied from [studioProjectBySlug].
  StudioProjectBySlugProvider call(
    String slug,
  ) {
    return StudioProjectBySlugProvider(
      slug,
    );
  }

  @override
  StudioProjectBySlugProvider getProviderOverride(
    covariant StudioProjectBySlugProvider provider,
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
  String? get name => r'studioProjectBySlugProvider';
}

/// One project with its episodes, by slug — served from the listing when it is
/// already loaded.
///
/// Copied from [studioProjectBySlug].
class StudioProjectBySlugProvider
    extends AutoDisposeFutureProvider<StudioProject?> {
  /// One project with its episodes, by slug — served from the listing when it is
  /// already loaded.
  ///
  /// Copied from [studioProjectBySlug].
  StudioProjectBySlugProvider(
    String slug,
  ) : this._internal(
          (ref) => studioProjectBySlug(
            ref as StudioProjectBySlugRef,
            slug,
          ),
          from: studioProjectBySlugProvider,
          name: r'studioProjectBySlugProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$studioProjectBySlugHash,
          dependencies: StudioProjectBySlugFamily._dependencies,
          allTransitiveDependencies:
              StudioProjectBySlugFamily._allTransitiveDependencies,
          slug: slug,
        );

  StudioProjectBySlugProvider._internal(
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
    FutureOr<StudioProject?> Function(StudioProjectBySlugRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StudioProjectBySlugProvider._internal(
        (ref) => create(ref as StudioProjectBySlugRef),
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
  AutoDisposeFutureProviderElement<StudioProject?> createElement() {
    return _StudioProjectBySlugProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudioProjectBySlugProvider && other.slug == slug;
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
mixin StudioProjectBySlugRef on AutoDisposeFutureProviderRef<StudioProject?> {
  /// The parameter `slug` of this provider.
  String get slug;
}

class _StudioProjectBySlugProviderElement
    extends AutoDisposeFutureProviderElement<StudioProject?>
    with StudioProjectBySlugRef {
  _StudioProjectBySlugProviderElement(super.provider);

  @override
  String get slug => (origin as StudioProjectBySlugProvider).slug;
}

String _$studioEpisodeHash() => r'd4c14f0454970fe1f9527e77aef934665a3735e2';

/// One episode, addressed by its project's slug and its own.
///
/// The episode page is always reached through a project, and episodes arrive
/// joined to it — so this resolves the project once and reads the episode out
/// of it rather than querying `studio_episodes` separately.
///
/// Copied from [studioEpisode].
@ProviderFor(studioEpisode)
const studioEpisodeProvider = StudioEpisodeFamily();

/// One episode, addressed by its project's slug and its own.
///
/// The episode page is always reached through a project, and episodes arrive
/// joined to it — so this resolves the project once and reads the episode out
/// of it rather than querying `studio_episodes` separately.
///
/// Copied from [studioEpisode].
class StudioEpisodeFamily extends Family<AsyncValue<StudioEpisode?>> {
  /// One episode, addressed by its project's slug and its own.
  ///
  /// The episode page is always reached through a project, and episodes arrive
  /// joined to it — so this resolves the project once and reads the episode out
  /// of it rather than querying `studio_episodes` separately.
  ///
  /// Copied from [studioEpisode].
  const StudioEpisodeFamily();

  /// One episode, addressed by its project's slug and its own.
  ///
  /// The episode page is always reached through a project, and episodes arrive
  /// joined to it — so this resolves the project once and reads the episode out
  /// of it rather than querying `studio_episodes` separately.
  ///
  /// Copied from [studioEpisode].
  StudioEpisodeProvider call(
    String projectSlug,
    String episodeSlug,
  ) {
    return StudioEpisodeProvider(
      projectSlug,
      episodeSlug,
    );
  }

  @override
  StudioEpisodeProvider getProviderOverride(
    covariant StudioEpisodeProvider provider,
  ) {
    return call(
      provider.projectSlug,
      provider.episodeSlug,
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
  String? get name => r'studioEpisodeProvider';
}

/// One episode, addressed by its project's slug and its own.
///
/// The episode page is always reached through a project, and episodes arrive
/// joined to it — so this resolves the project once and reads the episode out
/// of it rather than querying `studio_episodes` separately.
///
/// Copied from [studioEpisode].
class StudioEpisodeProvider extends AutoDisposeFutureProvider<StudioEpisode?> {
  /// One episode, addressed by its project's slug and its own.
  ///
  /// The episode page is always reached through a project, and episodes arrive
  /// joined to it — so this resolves the project once and reads the episode out
  /// of it rather than querying `studio_episodes` separately.
  ///
  /// Copied from [studioEpisode].
  StudioEpisodeProvider(
    String projectSlug,
    String episodeSlug,
  ) : this._internal(
          (ref) => studioEpisode(
            ref as StudioEpisodeRef,
            projectSlug,
            episodeSlug,
          ),
          from: studioEpisodeProvider,
          name: r'studioEpisodeProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$studioEpisodeHash,
          dependencies: StudioEpisodeFamily._dependencies,
          allTransitiveDependencies:
              StudioEpisodeFamily._allTransitiveDependencies,
          projectSlug: projectSlug,
          episodeSlug: episodeSlug,
        );

  StudioEpisodeProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.projectSlug,
    required this.episodeSlug,
  }) : super.internal();

  final String projectSlug;
  final String episodeSlug;

  @override
  Override overrideWith(
    FutureOr<StudioEpisode?> Function(StudioEpisodeRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StudioEpisodeProvider._internal(
        (ref) => create(ref as StudioEpisodeRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        projectSlug: projectSlug,
        episodeSlug: episodeSlug,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<StudioEpisode?> createElement() {
    return _StudioEpisodeProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudioEpisodeProvider &&
        other.projectSlug == projectSlug &&
        other.episodeSlug == episodeSlug;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, projectSlug.hashCode);
    hash = _SystemHash.combine(hash, episodeSlug.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin StudioEpisodeRef on AutoDisposeFutureProviderRef<StudioEpisode?> {
  /// The parameter `projectSlug` of this provider.
  String get projectSlug;

  /// The parameter `episodeSlug` of this provider.
  String get episodeSlug;
}

class _StudioEpisodeProviderElement
    extends AutoDisposeFutureProviderElement<StudioEpisode?>
    with StudioEpisodeRef {
  _StudioEpisodeProviderElement(super.provider);

  @override
  String get projectSlug => (origin as StudioEpisodeProvider).projectSlug;
  @override
  String get episodeSlug => (origin as StudioEpisodeProvider).episodeSlug;
}

String _$studioListHash() => r'345d82459f33ac630cef7236f5faa601253fc21f';

/// The Studio tab listing.
///
/// Copied from [StudioList].
@ProviderFor(StudioList)
final studioListProvider =
    AsyncNotifierProvider<StudioList, List<StudioProject>>.internal(
  StudioList.new,
  name: r'studioListProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$studioListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$StudioList = AsyncNotifier<List<StudioProject>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
