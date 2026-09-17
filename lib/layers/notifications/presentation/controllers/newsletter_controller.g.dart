// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'newsletter_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$newsletterArchiveHash() => r'cda2624b6c56fb8ab2a4e22bdc02efd1d0ec8c5c';

/// Past issues.
///
/// Not keepAlive, unlike the content tabs: this is one tab of one screen
/// somebody opens occasionally, and holding thirty issues of block JSON in
/// memory for the life of the app buys nothing.
///
/// Copied from [NewsletterArchive].
@ProviderFor(NewsletterArchive)
final newsletterArchiveProvider = AutoDisposeAsyncNotifierProvider<
    NewsletterArchive, List<NewsletterIssue>>.internal(
  NewsletterArchive.new,
  name: r'newsletterArchiveProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$newsletterArchiveHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$NewsletterArchive = AutoDisposeAsyncNotifier<List<NewsletterIssue>>;
String _$newsletterSubscriptionHash() =>
    r'15896a615580d8f914784a8ad513fbab878b0da3';

/// Whether this person is on the list, and the two ways to change that.
///
/// keepAlive because the answer is per-session and cheap to hold, and because
/// the tab would otherwise re-ask the server every time it is swiped back to.
///
/// Copied from [NewsletterSubscription].
@ProviderFor(NewsletterSubscription)
final newsletterSubscriptionProvider =
    AsyncNotifierProvider<NewsletterSubscription, NewsletterStatus>.internal(
  NewsletterSubscription.new,
  name: r'newsletterSubscriptionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$newsletterSubscriptionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$NewsletterSubscription = AsyncNotifier<NewsletterStatus>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
