import 'package:equatable/equatable.dart';
// `Ref` lives here, not in riverpod_annotation.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dsh_mobile/layers/support/data/repositories/donations_repository_impl.dart';
import 'package:dsh_mobile/layers/support/domain/entities/donation.dart';

part 'donation_controller.g.dart';

/// The amounts offered, in euro. The same four the website shows.
///
/// Presets are a prompt, not a limit — "Other" takes any amount at or above
/// the €1 floor the checkout route enforces.
const List<int> kDonationPresets = [10, 25, 50, 100];

/// What the donation card is currently showing.
///
/// Deliberately not an `AsyncValue`: this is a form, not a query. It exists
/// before anything is loaded and survives a failed submission, which is
/// exactly what a donor needs — a rejected amount should still be in the box
/// when the error appears.
class DonationFormState extends Equatable {
  final DonationMode mode;

  /// The chosen preset, or null when the donor is typing their own.
  final int? preset;

  /// What they typed. Only meaningful when [preset] is null.
  final String custom;

  final bool busy;
  final String? error;

  const DonationFormState({
    this.mode = DonationMode.monthly,
    this.preset = 25,
    this.custom = '',
    this.busy = false,
    this.error,
  });

  /// The amount to send, or null when there is nothing valid to send.
  ///
  /// Null disables the button. Letting someone press it and receive a 400
  /// from Stripe teaches them nothing and looks like the payment failed.
  double? get amount {
    if (preset != null) return preset!.toDouble();

    final parsed = double.tryParse(custom.replaceAll(',', '.').trim());
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  DonationFormState copyWith({
    DonationMode? mode,
    int? preset,
    bool clearPreset = false,
    String? custom,
    bool? busy,
    String? error,
    bool clearError = false,
  }) =>
      DonationFormState(
        mode: mode ?? this.mode,
        preset: clearPreset ? null : (preset ?? this.preset),
        custom: custom ?? this.custom,
        busy: busy ?? this.busy,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [mode, preset, custom, busy, error];
}

@riverpod
class DonationForm extends _$DonationForm {
  @override
  DonationFormState build() => const DonationFormState();

  void setMode(DonationMode mode) =>
      state = state.copyWith(mode: mode, clearError: true);

  void selectPreset(int amount) =>
      state = state.copyWith(preset: amount, custom: '', clearError: true);

  /// Typing switches away from the presets, so the two can never both look
  /// selected — a donor must always be able to see which number will be taken.
  void setCustom(String value) => state =
      state.copyWith(clearPreset: true, custom: value, clearError: true);

  /// Creates the Checkout session, or null if it could not be created — in
  /// which case `state.error` says why, in words written for a donor rather
  /// than a developer.
  ///
  /// Returns the whole session, not just its URL, because the id is needed
  /// afterwards: if the donor closes the payment view themselves we still have
  /// to be able to ask whether they paid first.
  Future<CheckoutSession?> startCheckout(FundingTarget? target) async {
    final amount = state.amount;
    if (amount == null || state.busy) return null;

    state = state.copyWith(busy: true, clearError: true);

    final result = await ref.read(donationsRepositoryProvider).startCheckout(
          mode: state.mode,
          amount: amount,
          target: target,
        );

    return result.fold(
      (failure) {
        state = state.copyWith(busy: false, error: failure.message);
        return null;
      },
      (session) {
        state = state.copyWith(busy: false);
        return session;
      },
    );
  }

  /// After the browser has been handed the URL. The card returns to a state a
  /// donor can act on — they may come straight back without having paid.
  void reset() => state = state.copyWith(busy: false, clearError: true);
}

/// Whether the site is taking real money.
///
/// Warning a donor BEFORE they enter a card is the entire point: in test mode
/// Stripe accepts a real card number, the page says thank you, and nothing is
/// charged. There is no error anywhere to tell them otherwise.
///
/// Resolves to null when the answer is unknown — the screen then says nothing.
@riverpod
Future<bool?> stripeTestMode(Ref ref) async {
  final result = await ref.read(donationsRepositoryProvider).isTestMode();
  return result.fold((_) => null, (isTest) => isTest);
}
