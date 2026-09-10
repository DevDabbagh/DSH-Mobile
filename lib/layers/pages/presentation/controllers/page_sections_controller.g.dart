// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_sections_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pageSectionsListHash() => r'8b95e9ceb55932d1ca1c5a3ababce42e9b4eeeb7';

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

abstract class _$PageSectionsList
    extends BuildlessAutoDisposeAsyncNotifier<List<PageSection>> {
  late final String page;

  FutureOr<List<PageSection>> build(
    String page,
  );
}

/// The sections of one editable page, in order.
///
/// Parameterised by page name so About, and later Support or anything else the
/// Pages editor gains, all share this one controller rather than each growing
/// a near-identical copy.
///
/// The failure is thrown rather than swallowed: an empty page and a page that
/// failed to load look identical to a reader otherwise, and only one of them
/// deserves a retry button.
///
/// Copied from [PageSectionsList].
@ProviderFor(PageSectionsList)
const pageSectionsListProvider = PageSectionsListFamily();

/// The sections of one editable page, in order.
///
/// Parameterised by page name so About, and later Support or anything else the
/// Pages editor gains, all share this one controller rather than each growing
/// a near-identical copy.
///
/// The failure is thrown rather than swallowed: an empty page and a page that
/// failed to load look identical to a reader otherwise, and only one of them
/// deserves a retry button.
///
/// Copied from [PageSectionsList].
class PageSectionsListFamily extends Family<AsyncValue<List<PageSection>>> {
  /// The sections of one editable page, in order.
  ///
  /// Parameterised by page name so About, and later Support or anything else the
  /// Pages editor gains, all share this one controller rather than each growing
  /// a near-identical copy.
  ///
  /// The failure is thrown rather than swallowed: an empty page and a page that
  /// failed to load look identical to a reader otherwise, and only one of them
  /// deserves a retry button.
  ///
  /// Copied from [PageSectionsList].
  const PageSectionsListFamily();

  /// The sections of one editable page, in order.
  ///
  /// Parameterised by page name so About, and later Support or anything else the
  /// Pages editor gains, all share this one controller rather than each growing
  /// a near-identical copy.
  ///
  /// The failure is thrown rather than swallowed: an empty page and a page that
  /// failed to load look identical to a reader otherwise, and only one of them
  /// deserves a retry button.
  ///
  /// Copied from [PageSectionsList].
  PageSectionsListProvider call(
    String page,
  ) {
    return PageSectionsListProvider(
      page,
    );
  }

  @override
  PageSectionsListProvider getProviderOverride(
    covariant PageSectionsListProvider provider,
  ) {
    return call(
      provider.page,
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
  String? get name => r'pageSectionsListProvider';
}

/// The sections of one editable page, in order.
///
/// Parameterised by page name so About, and later Support or anything else the
/// Pages editor gains, all share this one controller rather than each growing
/// a near-identical copy.
///
/// The failure is thrown rather than swallowed: an empty page and a page that
/// failed to load look identical to a reader otherwise, and only one of them
/// deserves a retry button.
///
/// Copied from [PageSectionsList].
class PageSectionsListProvider extends AutoDisposeAsyncNotifierProviderImpl<
    PageSectionsList, List<PageSection>> {
  /// The sections of one editable page, in order.
  ///
  /// Parameterised by page name so About, and later Support or anything else the
  /// Pages editor gains, all share this one controller rather than each growing
  /// a near-identical copy.
  ///
  /// The failure is thrown rather than swallowed: an empty page and a page that
  /// failed to load look identical to a reader otherwise, and only one of them
  /// deserves a retry button.
  ///
  /// Copied from [PageSectionsList].
  PageSectionsListProvider(
    String page,
  ) : this._internal(
          () => PageSectionsList()..page = page,
          from: pageSectionsListProvider,
          name: r'pageSectionsListProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$pageSectionsListHash,
          dependencies: PageSectionsListFamily._dependencies,
          allTransitiveDependencies:
              PageSectionsListFamily._allTransitiveDependencies,
          page: page,
        );

  PageSectionsListProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.page,
  }) : super.internal();

  final String page;

  @override
  FutureOr<List<PageSection>> runNotifierBuild(
    covariant PageSectionsList notifier,
  ) {
    return notifier.build(
      page,
    );
  }

  @override
  Override overrideWith(PageSectionsList Function() create) {
    return ProviderOverride(
      origin: this,
      override: PageSectionsListProvider._internal(
        () => create()..page = page,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        page: page,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<PageSectionsList, List<PageSection>>
      createElement() {
    return _PageSectionsListProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PageSectionsListProvider && other.page == page;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, page.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PageSectionsListRef
    on AutoDisposeAsyncNotifierProviderRef<List<PageSection>> {
  /// The parameter `page` of this provider.
  String get page;
}

class _PageSectionsListProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<PageSectionsList,
        List<PageSection>> with PageSectionsListRef {
  _PageSectionsListProviderElement(super.provider);

  @override
  String get page => (origin as PageSectionsListProvider).page;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
