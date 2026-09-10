// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'academy_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$academyProgramBySlugHash() =>
    r'a7c9930b3a24284eaf85693c4db2039633db65f1';

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

/// One programme, by slug.
///
/// Reuses the already-loaded listing when it holds the programme, so opening
/// a card shows content immediately instead of a spinner over data the app
/// already has.
///
/// Copied from [academyProgramBySlug].
@ProviderFor(academyProgramBySlug)
const academyProgramBySlugProvider = AcademyProgramBySlugFamily();

/// One programme, by slug.
///
/// Reuses the already-loaded listing when it holds the programme, so opening
/// a card shows content immediately instead of a spinner over data the app
/// already has.
///
/// Copied from [academyProgramBySlug].
class AcademyProgramBySlugFamily extends Family<AsyncValue<AcademyProgram?>> {
  /// One programme, by slug.
  ///
  /// Reuses the already-loaded listing when it holds the programme, so opening
  /// a card shows content immediately instead of a spinner over data the app
  /// already has.
  ///
  /// Copied from [academyProgramBySlug].
  const AcademyProgramBySlugFamily();

  /// One programme, by slug.
  ///
  /// Reuses the already-loaded listing when it holds the programme, so opening
  /// a card shows content immediately instead of a spinner over data the app
  /// already has.
  ///
  /// Copied from [academyProgramBySlug].
  AcademyProgramBySlugProvider call(
    String slug,
  ) {
    return AcademyProgramBySlugProvider(
      slug,
    );
  }

  @override
  AcademyProgramBySlugProvider getProviderOverride(
    covariant AcademyProgramBySlugProvider provider,
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
  String? get name => r'academyProgramBySlugProvider';
}

/// One programme, by slug.
///
/// Reuses the already-loaded listing when it holds the programme, so opening
/// a card shows content immediately instead of a spinner over data the app
/// already has.
///
/// Copied from [academyProgramBySlug].
class AcademyProgramBySlugProvider
    extends AutoDisposeFutureProvider<AcademyProgram?> {
  /// One programme, by slug.
  ///
  /// Reuses the already-loaded listing when it holds the programme, so opening
  /// a card shows content immediately instead of a spinner over data the app
  /// already has.
  ///
  /// Copied from [academyProgramBySlug].
  AcademyProgramBySlugProvider(
    String slug,
  ) : this._internal(
          (ref) => academyProgramBySlug(
            ref as AcademyProgramBySlugRef,
            slug,
          ),
          from: academyProgramBySlugProvider,
          name: r'academyProgramBySlugProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$academyProgramBySlugHash,
          dependencies: AcademyProgramBySlugFamily._dependencies,
          allTransitiveDependencies:
              AcademyProgramBySlugFamily._allTransitiveDependencies,
          slug: slug,
        );

  AcademyProgramBySlugProvider._internal(
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
    FutureOr<AcademyProgram?> Function(AcademyProgramBySlugRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AcademyProgramBySlugProvider._internal(
        (ref) => create(ref as AcademyProgramBySlugRef),
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
  AutoDisposeFutureProviderElement<AcademyProgram?> createElement() {
    return _AcademyProgramBySlugProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AcademyProgramBySlugProvider && other.slug == slug;
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
mixin AcademyProgramBySlugRef on AutoDisposeFutureProviderRef<AcademyProgram?> {
  /// The parameter `slug` of this provider.
  String get slug;
}

class _AcademyProgramBySlugProviderElement
    extends AutoDisposeFutureProviderElement<AcademyProgram?>
    with AcademyProgramBySlugRef {
  _AcademyProgramBySlugProviderElement(super.provider);

  @override
  String get slug => (origin as AcademyProgramBySlugProvider).slug;
}

String _$academyProgramsHash() => r'ecad1ef14299ca25a446268be26953efdda8d1af';

/// The Academy tab listing.
///
/// A failure is thrown rather than folded away so the screen can offer a
/// retry — an empty list here is a real state ("nothing published yet") and
/// has to stay distinguishable from a failure.
///
/// Copied from [AcademyPrograms].
@ProviderFor(AcademyPrograms)
final academyProgramsProvider =
    AsyncNotifierProvider<AcademyPrograms, List<AcademyProgram>>.internal(
  AcademyPrograms.new,
  name: r'academyProgramsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$academyProgramsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AcademyPrograms = AsyncNotifier<List<AcademyProgram>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
