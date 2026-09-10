// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'impact_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$impactRepositoryHash() => r'f40d05741bc67f865990459b0d251b91cfa79191';

/// See also [impactRepository].
@ProviderFor(impactRepository)
final impactRepositoryProvider = AutoDisposeProvider<ImpactRepository>.internal(
  impactRepository,
  name: r'impactRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$impactRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ImpactRepositoryRef = AutoDisposeProviderRef<ImpactRepository>;
String _$impactStatsHash() => r'a1251d988eca30183d2f2d9cd4fffd00cd5e2706';

/// The Impact rail's figures. keepAlive, like the other content lists.
///
/// Copied from [impactStats].
@ProviderFor(impactStats)
final impactStatsProvider = FutureProvider<List<ImpactStat>>.internal(
  impactStats,
  name: r'impactStatsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$impactStatsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ImpactStatsRef = FutureProviderRef<List<ImpactStat>>;
String _$impactStoriesHash() => r'18aabbe60beee832c2e73b6c0b0b2de15570704a';

/// The Impact screen's stories.
///
/// Copied from [impactStories].
@ProviderFor(impactStories)
final impactStoriesProvider = FutureProvider<List<ImpactStory>>.internal(
  impactStories,
  name: r'impactStoriesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$impactStoriesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ImpactStoriesRef = FutureProviderRef<List<ImpactStory>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
