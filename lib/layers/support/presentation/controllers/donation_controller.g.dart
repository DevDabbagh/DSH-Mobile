// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'donation_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$stripeTestModeHash() => r'94366ba81863a4a2ef3fdaa90069173179270c5a';

/// Whether the site is taking real money.
///
/// Warning a donor BEFORE they enter a card is the entire point: in test mode
/// Stripe accepts a real card number, the page says thank you, and nothing is
/// charged. There is no error anywhere to tell them otherwise.
///
/// Resolves to null when the answer is unknown — the screen then says nothing.
///
/// Copied from [stripeTestMode].
@ProviderFor(stripeTestMode)
final stripeTestModeProvider = AutoDisposeFutureProvider<bool?>.internal(
  stripeTestMode,
  name: r'stripeTestModeProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$stripeTestModeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StripeTestModeRef = AutoDisposeFutureProviderRef<bool?>;
String _$donationFormHash() => r'bc9d1b910b913d00496834347ac6e33f3db40c09';

/// See also [DonationForm].
@ProviderFor(DonationForm)
final donationFormProvider =
    AutoDisposeNotifierProvider<DonationForm, DonationFormState>.internal(
  DonationForm.new,
  name: r'donationFormProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$donationFormHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$DonationForm = AutoDisposeNotifier<DonationFormState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
