import 'package:dartz/dartz.dart';

import 'package:dsh_mobile/app/core/errors/failures.dart';
import 'package:dsh_mobile/layers/notifications/domain/entities/newsletter_issue.dart';

/// Where this person stands with the newsletter.
///
/// The words are `newsletter_subscribers.status` from migration 014, plus
/// [none] for an address that has never been on the list.
enum NewsletterStatus {
  /// Signed up but has not clicked the link in the confirmation email. NOT on
  /// the list — double opt-in means nothing is sent until they answer.
  pending,

  subscribed,
  unsubscribed,

  /// The provider told us this address is dead.
  bounced,

  /// They pressed "spam".
  complained,

  none;

  static NewsletterStatus fromDb(String? value) => switch (value) {
        'pending' => NewsletterStatus.pending,
        'subscribed' => NewsletterStatus.subscribed,
        'unsubscribed' => NewsletterStatus.unsubscribed,
        'bounced' => NewsletterStatus.bounced,
        'complained' => NewsletterStatus.complained,
        _ => NewsletterStatus.none,
      };

  /// Whether the screen may offer to subscribe.
  ///
  /// [bounced] and [complained] are excluded on purpose. Re-subscribing an
  /// address that hard-bounced, or someone who reported DSH as spam, is what
  /// destroys a sending domain's reputation — and password resets leave from
  /// the same domain, so it would take those down too. The RPC refuses as
  /// well; this stops the app offering a button that can only fail.
  bool get canSubscribe => switch (this) {
        NewsletterStatus.none ||
        NewsletterStatus.unsubscribed ||
        NewsletterStatus.pending =>
          true,
        _ => false,
      };

  bool get canUnsubscribe =>
      this == NewsletterStatus.subscribed || this == NewsletterStatus.pending;
}

abstract class NewsletterRepository {
  /// Past issues, newest first. Public — a sent issue is already in several
  /// hundred inboxes — so this works for a guest too.
  Future<Either<Failure, List<NewsletterIssue>>> getArchive();

  /// The caller's own status. [NewsletterStatus.none] for a guest: there is no
  /// verified address to ask about.
  Future<Either<Failure, NewsletterStatus>> myStatus();

  /// Signs the caller's own address up. Lands as `pending` — the confirmation
  /// email decides the rest.
  Future<Either<Failure, Unit>> subscribe(String email);

  Future<Either<Failure, Unit>> unsubscribe();
}
