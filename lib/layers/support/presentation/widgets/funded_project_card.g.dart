// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'funded_project_card.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$fundedProjectImageHash() =>
    r'df20cacc53fd12c535960bee4709d77a9bf177e0';

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

/// The poster for the project a donor arrived to fund.
///
/// The route carries only type, slug and title — a URL is a bad place to keep
/// an image, and pinning one there would freeze the poster to whatever it was
/// the day the link was made. So the picture is looked up here, from the same
/// providers the film and studio screens already use, which usually means it
/// is already cached and appears instantly.
///
/// Returns null on any failure. **A missing poster must never block a
/// donation** — the card falls back to the title, which the route already gave
/// us, and the money still moves.
///
/// Copied from [fundedProjectImage].
@ProviderFor(fundedProjectImage)
const fundedProjectImageProvider = FundedProjectImageFamily();

/// The poster for the project a donor arrived to fund.
///
/// The route carries only type, slug and title — a URL is a bad place to keep
/// an image, and pinning one there would freeze the poster to whatever it was
/// the day the link was made. So the picture is looked up here, from the same
/// providers the film and studio screens already use, which usually means it
/// is already cached and appears instantly.
///
/// Returns null on any failure. **A missing poster must never block a
/// donation** — the card falls back to the title, which the route already gave
/// us, and the money still moves.
///
/// Copied from [fundedProjectImage].
class FundedProjectImageFamily extends Family<AsyncValue<String?>> {
  /// The poster for the project a donor arrived to fund.
  ///
  /// The route carries only type, slug and title — a URL is a bad place to keep
  /// an image, and pinning one there would freeze the poster to whatever it was
  /// the day the link was made. So the picture is looked up here, from the same
  /// providers the film and studio screens already use, which usually means it
  /// is already cached and appears instantly.
  ///
  /// Returns null on any failure. **A missing poster must never block a
  /// donation** — the card falls back to the title, which the route already gave
  /// us, and the money still moves.
  ///
  /// Copied from [fundedProjectImage].
  const FundedProjectImageFamily();

  /// The poster for the project a donor arrived to fund.
  ///
  /// The route carries only type, slug and title — a URL is a bad place to keep
  /// an image, and pinning one there would freeze the poster to whatever it was
  /// the day the link was made. So the picture is looked up here, from the same
  /// providers the film and studio screens already use, which usually means it
  /// is already cached and appears instantly.
  ///
  /// Returns null on any failure. **A missing poster must never block a
  /// donation** — the card falls back to the title, which the route already gave
  /// us, and the money still moves.
  ///
  /// Copied from [fundedProjectImage].
  FundedProjectImageProvider call({
    required String type,
    required String slug,
  }) {
    return FundedProjectImageProvider(
      type: type,
      slug: slug,
    );
  }

  @override
  FundedProjectImageProvider getProviderOverride(
    covariant FundedProjectImageProvider provider,
  ) {
    return call(
      type: provider.type,
      slug: provider.slug,
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
  String? get name => r'fundedProjectImageProvider';
}

/// The poster for the project a donor arrived to fund.
///
/// The route carries only type, slug and title — a URL is a bad place to keep
/// an image, and pinning one there would freeze the poster to whatever it was
/// the day the link was made. So the picture is looked up here, from the same
/// providers the film and studio screens already use, which usually means it
/// is already cached and appears instantly.
///
/// Returns null on any failure. **A missing poster must never block a
/// donation** — the card falls back to the title, which the route already gave
/// us, and the money still moves.
///
/// Copied from [fundedProjectImage].
class FundedProjectImageProvider extends AutoDisposeFutureProvider<String?> {
  /// The poster for the project a donor arrived to fund.
  ///
  /// The route carries only type, slug and title — a URL is a bad place to keep
  /// an image, and pinning one there would freeze the poster to whatever it was
  /// the day the link was made. So the picture is looked up here, from the same
  /// providers the film and studio screens already use, which usually means it
  /// is already cached and appears instantly.
  ///
  /// Returns null on any failure. **A missing poster must never block a
  /// donation** — the card falls back to the title, which the route already gave
  /// us, and the money still moves.
  ///
  /// Copied from [fundedProjectImage].
  FundedProjectImageProvider({
    required String type,
    required String slug,
  }) : this._internal(
          (ref) => fundedProjectImage(
            ref as FundedProjectImageRef,
            type: type,
            slug: slug,
          ),
          from: fundedProjectImageProvider,
          name: r'fundedProjectImageProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$fundedProjectImageHash,
          dependencies: FundedProjectImageFamily._dependencies,
          allTransitiveDependencies:
              FundedProjectImageFamily._allTransitiveDependencies,
          type: type,
          slug: slug,
        );

  FundedProjectImageProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.type,
    required this.slug,
  }) : super.internal();

  final String type;
  final String slug;

  @override
  Override overrideWith(
    FutureOr<String?> Function(FundedProjectImageRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FundedProjectImageProvider._internal(
        (ref) => create(ref as FundedProjectImageRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        type: type,
        slug: slug,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<String?> createElement() {
    return _FundedProjectImageProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FundedProjectImageProvider &&
        other.type == type &&
        other.slug == slug;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, type.hashCode);
    hash = _SystemHash.combine(hash, slug.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FundedProjectImageRef on AutoDisposeFutureProviderRef<String?> {
  /// The parameter `type` of this provider.
  String get type;

  /// The parameter `slug` of this provider.
  String get slug;
}

class _FundedProjectImageProviderElement
    extends AutoDisposeFutureProviderElement<String?>
    with FundedProjectImageRef {
  _FundedProjectImageProviderElement(super.provider);

  @override
  String get type => (origin as FundedProjectImageProvider).type;
  @override
  String get slug => (origin as FundedProjectImageProvider).slug;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
