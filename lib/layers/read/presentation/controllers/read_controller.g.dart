// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'read_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$articleBySlugHash() => r'14ce736242d8c6513d5789806d8f97eff3a7a096';

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

/// One article, by slug.
///
/// NOT served from the listing's cache, unlike Academy's equivalent. The
/// listing deliberately carries no bodies, so a cache hit here would hand the
/// details screen an article with nothing to read and no way to tell that
/// from a locked one.
///
/// Copied from [articleBySlug].
@ProviderFor(articleBySlug)
const articleBySlugProvider = ArticleBySlugFamily();

/// One article, by slug.
///
/// NOT served from the listing's cache, unlike Academy's equivalent. The
/// listing deliberately carries no bodies, so a cache hit here would hand the
/// details screen an article with nothing to read and no way to tell that
/// from a locked one.
///
/// Copied from [articleBySlug].
class ArticleBySlugFamily extends Family<AsyncValue<Article?>> {
  /// One article, by slug.
  ///
  /// NOT served from the listing's cache, unlike Academy's equivalent. The
  /// listing deliberately carries no bodies, so a cache hit here would hand the
  /// details screen an article with nothing to read and no way to tell that
  /// from a locked one.
  ///
  /// Copied from [articleBySlug].
  const ArticleBySlugFamily();

  /// One article, by slug.
  ///
  /// NOT served from the listing's cache, unlike Academy's equivalent. The
  /// listing deliberately carries no bodies, so a cache hit here would hand the
  /// details screen an article with nothing to read and no way to tell that
  /// from a locked one.
  ///
  /// Copied from [articleBySlug].
  ArticleBySlugProvider call(
    String slug,
  ) {
    return ArticleBySlugProvider(
      slug,
    );
  }

  @override
  ArticleBySlugProvider getProviderOverride(
    covariant ArticleBySlugProvider provider,
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
  String? get name => r'articleBySlugProvider';
}

/// One article, by slug.
///
/// NOT served from the listing's cache, unlike Academy's equivalent. The
/// listing deliberately carries no bodies, so a cache hit here would hand the
/// details screen an article with nothing to read and no way to tell that
/// from a locked one.
///
/// Copied from [articleBySlug].
class ArticleBySlugProvider extends AutoDisposeFutureProvider<Article?> {
  /// One article, by slug.
  ///
  /// NOT served from the listing's cache, unlike Academy's equivalent. The
  /// listing deliberately carries no bodies, so a cache hit here would hand the
  /// details screen an article with nothing to read and no way to tell that
  /// from a locked one.
  ///
  /// Copied from [articleBySlug].
  ArticleBySlugProvider(
    String slug,
  ) : this._internal(
          (ref) => articleBySlug(
            ref as ArticleBySlugRef,
            slug,
          ),
          from: articleBySlugProvider,
          name: r'articleBySlugProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$articleBySlugHash,
          dependencies: ArticleBySlugFamily._dependencies,
          allTransitiveDependencies:
              ArticleBySlugFamily._allTransitiveDependencies,
          slug: slug,
        );

  ArticleBySlugProvider._internal(
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
    FutureOr<Article?> Function(ArticleBySlugRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ArticleBySlugProvider._internal(
        (ref) => create(ref as ArticleBySlugRef),
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
  AutoDisposeFutureProviderElement<Article?> createElement() {
    return _ArticleBySlugProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ArticleBySlugProvider && other.slug == slug;
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
mixin ArticleBySlugRef on AutoDisposeFutureProviderRef<Article?> {
  /// The parameter `slug` of this provider.
  String get slug;
}

class _ArticleBySlugProviderElement
    extends AutoDisposeFutureProviderElement<Article?> with ArticleBySlugRef {
  _ArticleBySlugProviderElement(super.provider);

  @override
  String get slug => (origin as ArticleBySlugProvider).slug;
}

String _$readArticlesHash() => r'799bdcc627951cf647aaa6443ee7583ec4a3240a';

/// The Read listing.
///
/// keepAlive, like Films, Studio and Academy: fetched once and kept across
/// tab switches, so coming back does not re-query and re-render every card
/// from its placeholder.
///
/// Copied from [ReadArticles].
@ProviderFor(ReadArticles)
final readArticlesProvider =
    AsyncNotifierProvider<ReadArticles, List<Article>>.internal(
  ReadArticles.new,
  name: r'readArticlesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$readArticlesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ReadArticles = AsyncNotifier<List<Article>>;
String _$readFilterControllerHash() =>
    r'c832f447738cf68eff8affc2854dc17ab0a0c46b';

/// See also [ReadFilterController].
@ProviderFor(ReadFilterController)
final readFilterControllerProvider =
    AutoDisposeNotifierProvider<ReadFilterController, ReadFilter>.internal(
  ReadFilterController.new,
  name: r'readFilterControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$readFilterControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ReadFilterController = AutoDisposeNotifier<ReadFilter>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
