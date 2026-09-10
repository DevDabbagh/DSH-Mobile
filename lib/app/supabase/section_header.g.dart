// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'section_header.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$sectionHeaderHash() => r'20b159aa878e9f79509bd4d4a4c6dff870c9f322';

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

/// Reads one section's header settings.
///
/// keepAlive: three small rows that change when an editor saves, not while
/// someone is scrolling. Re-reading them on every visit to the tab would be a
/// query for a value that is almost always the same.
///
/// A failure returns the default rather than throwing — the header is
/// decoration around a listing, and a listing that refuses to render because
/// its wallpaper could not be read would be the wrong trade.
///
/// Copied from [sectionHeader].
@ProviderFor(sectionHeader)
const sectionHeaderProvider = SectionHeaderFamily();

/// Reads one section's header settings.
///
/// keepAlive: three small rows that change when an editor saves, not while
/// someone is scrolling. Re-reading them on every visit to the tab would be a
/// query for a value that is almost always the same.
///
/// A failure returns the default rather than throwing — the header is
/// decoration around a listing, and a listing that refuses to render because
/// its wallpaper could not be read would be the wrong trade.
///
/// Copied from [sectionHeader].
class SectionHeaderFamily extends Family<AsyncValue<SectionHeader>> {
  /// Reads one section's header settings.
  ///
  /// keepAlive: three small rows that change when an editor saves, not while
  /// someone is scrolling. Re-reading them on every visit to the tab would be a
  /// query for a value that is almost always the same.
  ///
  /// A failure returns the default rather than throwing — the header is
  /// decoration around a listing, and a listing that refuses to render because
  /// its wallpaper could not be read would be the wrong trade.
  ///
  /// Copied from [sectionHeader].
  const SectionHeaderFamily();

  /// Reads one section's header settings.
  ///
  /// keepAlive: three small rows that change when an editor saves, not while
  /// someone is scrolling. Re-reading them on every visit to the tab would be a
  /// query for a value that is almost always the same.
  ///
  /// A failure returns the default rather than throwing — the header is
  /// decoration around a listing, and a listing that refuses to render because
  /// its wallpaper could not be read would be the wrong trade.
  ///
  /// Copied from [sectionHeader].
  SectionHeaderProvider call(
    SectionHeaderKey key,
  ) {
    return SectionHeaderProvider(
      key,
    );
  }

  @override
  SectionHeaderProvider getProviderOverride(
    covariant SectionHeaderProvider provider,
  ) {
    return call(
      provider.key,
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
  String? get name => r'sectionHeaderProvider';
}

/// Reads one section's header settings.
///
/// keepAlive: three small rows that change when an editor saves, not while
/// someone is scrolling. Re-reading them on every visit to the tab would be a
/// query for a value that is almost always the same.
///
/// A failure returns the default rather than throwing — the header is
/// decoration around a listing, and a listing that refuses to render because
/// its wallpaper could not be read would be the wrong trade.
///
/// Copied from [sectionHeader].
class SectionHeaderProvider extends FutureProvider<SectionHeader> {
  /// Reads one section's header settings.
  ///
  /// keepAlive: three small rows that change when an editor saves, not while
  /// someone is scrolling. Re-reading them on every visit to the tab would be a
  /// query for a value that is almost always the same.
  ///
  /// A failure returns the default rather than throwing — the header is
  /// decoration around a listing, and a listing that refuses to render because
  /// its wallpaper could not be read would be the wrong trade.
  ///
  /// Copied from [sectionHeader].
  SectionHeaderProvider(
    SectionHeaderKey key,
  ) : this._internal(
          (ref) => sectionHeader(
            ref as SectionHeaderRef,
            key,
          ),
          from: sectionHeaderProvider,
          name: r'sectionHeaderProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$sectionHeaderHash,
          dependencies: SectionHeaderFamily._dependencies,
          allTransitiveDependencies:
              SectionHeaderFamily._allTransitiveDependencies,
          key: key,
        );

  SectionHeaderProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.key,
  }) : super.internal();

  final SectionHeaderKey key;

  @override
  Override overrideWith(
    FutureOr<SectionHeader> Function(SectionHeaderRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SectionHeaderProvider._internal(
        (ref) => create(ref as SectionHeaderRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        key: key,
      ),
    );
  }

  @override
  FutureProviderElement<SectionHeader> createElement() {
    return _SectionHeaderProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SectionHeaderProvider && other.key == key;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, key.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SectionHeaderRef on FutureProviderRef<SectionHeader> {
  /// The parameter `key` of this provider.
  SectionHeaderKey get key;
}

class _SectionHeaderProviderElement extends FutureProviderElement<SectionHeader>
    with SectionHeaderRef {
  _SectionHeaderProviderElement(super.provider);

  @override
  SectionHeaderKey get key => (origin as SectionHeaderProvider).key;
}

String _$headerImagePoolsHash() => r'edde6d8716738993d477f05deeea56dd4ce5a034';

/// Every catalogue a header wall may import posters from.
///
/// Reads the three content providers the app already keeps alive rather than
/// querying again — Films, Studio and Academy are all loaded by the time any
/// header renders, and a fourth round-trip for images that are already in
/// memory would be a query for nothing.
///
/// keepAlive so the three heroes share one map.
///
/// Copied from [headerImagePools].
@ProviderFor(headerImagePools)
final headerImagePoolsProvider = Provider<HeaderImagePools>.internal(
  headerImagePools,
  name: r'headerImagePoolsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$headerImagePoolsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HeaderImagePoolsRef = ProviderRef<HeaderImagePools>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
