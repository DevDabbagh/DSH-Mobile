import 'package:dartz/dartz.dart';

import 'package:dsh_mobile/app/core/errors/failures.dart';
import 'package:dsh_mobile/layers/support/domain/entities/donation.dart';

abstract class DonationsRepository {
  /// Asks the website to open a Stripe Checkout session and returns where to
  /// send the donor.
  ///
  /// [amount] is in euro, in major units — 25 means €25. The server re-checks
  /// it and pins the currency; nothing here is trusted on the other side.
  Future<Either<Failure, CheckoutSession>> startCheckout({
    required DonationMode mode,
    required double amount,
    FundingTarget? target,
  });

  /// Confirms a finished session and, in the same call, records the donation.
  ///
  /// Called once the checkout view closes. The webhook usually files the gift
  /// first, and the write is idempotent on the session id — but the webhook
  /// can be late, or not configured on this environment at all, and a donor
  /// must never be left unthanked because of it.
  Future<Either<Failure, DonationReceipt>> verifySession(String sessionId);

  /// The donor's answer on the thank-you screen: their name and email, or
  /// anonymity. First answer wins on the server — this cannot be used to
  /// overwrite a choice already made.
  Future<Either<Failure, Unit>> claimDonation({
    required String sessionId,
    required bool anonymous,
    String? name,
    String? email,
  });

  /// Whether the site is in Stripe test mode, so the screen can say so before
  /// anyone types a card.
  ///
  /// `Right(null)` means the answer is unknown — the site did not respond, or
  /// gave something unexpected. The screen says nothing in that case rather
  /// than warning a donor on a live site that their money will not move.
  Future<Either<Failure, bool?>> isTestMode();
}
