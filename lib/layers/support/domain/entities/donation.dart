import 'package:equatable/equatable.dart';

/// How often the money moves.
///
/// Two options and no plan tiers. That is a product decision, not a
/// simplification of the web: DSH asks for monthly or one-time support, and
/// naming tiers ("Supporter", "Patron") would sort donors into ranks the
/// organisation does not want to draw.
enum DonationMode {
  oneTime,
  monthly;

  /// The value the checkout route expects. It compares against `"monthly"`
  /// and treats anything else as one-time, but sending the exact string keeps
  /// the two sides readable together.
  String get wire => this == DonationMode.monthly ? 'monthly' : 'one_time';
}

/// The project a donor arrived to fund.
///
/// Carried on the route from a film or studio screen, exactly as the website
/// carries it in the query string. Without it a donation is general support;
/// with it the money is attributed to the project in Stripe's metadata, which
/// is what lets the dashboard report per-project totals.
class FundingTarget extends Equatable {
  /// `film` · `studio` · `academy` — the checkout route rejects anything else
  /// and silently drops the attribution, so it is validated before it is sent.
  final String type;
  final String slug;
  final String title;

  const FundingTarget({
    required this.type,
    required this.slug,
    required this.title,
  });

  static const _allowedTypes = {'film', 'studio', 'academy'};

  /// Builds a target from route parameters, or null when they do not describe
  /// one. All three are required: a slug with no title gives the donor a card
  /// with nothing on it, and a title with no slug cannot be attributed.
  static FundingTarget? fromParams({
    String? type,
    String? slug,
    String? title,
  }) {
    final t = type?.trim() ?? '';
    final s = slug?.trim() ?? '';
    final ti = title?.trim() ?? '';

    if (!_allowedTypes.contains(t) || s.isEmpty || ti.isEmpty) return null;
    return FundingTarget(type: t, slug: s, title: ti);
  }

  @override
  List<Object?> get props => [type, slug, title];
}

/// What a finished payment turned out to be.
///
/// Comes back from the site's verify endpoint, which is also what records the
/// donation — so this is both the receipt and the act of filing it.
///
/// [paid] false is a real answer, not a failure: Stripe reports a session that
/// exists but was never completed, and the donor should be told nothing was
/// taken rather than thanked for a gift that did not happen.
class DonationReceipt extends Equatable {
  final bool paid;
  final double amount;
  final String currency;
  final String? email;
  final String? name;
  final DonationMode mode;
  final String? projectTitle;

  const DonationReceipt({
    required this.paid,
    this.amount = 0,
    this.currency = 'eur',
    this.email,
    this.name,
    this.mode = DonationMode.oneTime,
    this.projectTitle,
  });

  @override
  List<Object?> get props =>
      [paid, amount, currency, email, name, mode, projectTitle];
}

/// A Stripe Checkout session, created by the website and opened in a browser.
///
/// The app never sees a card number. It asks the site to create the session,
/// then hands the URL to the browser — the secret key stays on the server and
/// the app stays out of PCI scope entirely.
class CheckoutSession extends Equatable {
  final String url;
  final String id;

  const CheckoutSession({required this.url, required this.id});

  @override
  List<Object?> get props => [url, id];
}
