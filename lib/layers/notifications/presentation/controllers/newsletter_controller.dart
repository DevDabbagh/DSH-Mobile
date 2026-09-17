import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dsh_mobile/layers/notifications/data/repositories/newsletter_repository_impl.dart';
import 'package:dsh_mobile/layers/notifications/domain/entities/newsletter_issue.dart';
import 'package:dsh_mobile/layers/notifications/domain/repositories/newsletter_repository.dart';

part 'newsletter_controller.g.dart';

/// Past issues.
///
/// Not keepAlive, unlike the content tabs: this is one tab of one screen
/// somebody opens occasionally, and holding thirty issues of block JSON in
/// memory for the life of the app buys nothing.
@riverpod
class NewsletterArchive extends _$NewsletterArchive {
  @override
  Future<List<NewsletterIssue>> build() async {
    final result = await ref.watch(newsletterRepositoryProvider).getArchive();
    return result.fold((failure) => throw failure, (issues) => issues);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    final result = await ref.read(newsletterRepositoryProvider).getArchive();
    state = result.fold(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (issues) => AsyncValue.data(issues),
    );
  }
}

/// Whether this person is on the list, and the two ways to change that.
///
/// keepAlive because the answer is per-session and cheap to hold, and because
/// the tab would otherwise re-ask the server every time it is swiped back to.
@Riverpod(keepAlive: true)
class NewsletterSubscription extends _$NewsletterSubscription {
  @override
  Future<NewsletterStatus> build() async {
    // Signing in or out changes whose status this is. The repository provider
    // is rebuilt on that, and watching it here means this is too.
    final result = await ref.watch(newsletterRepositoryProvider).myStatus();
    return result.fold((_) => NewsletterStatus.none, (status) => status);
  }

  /// Returns null on success, or the message to show.
  ///
  /// NOT ROUTED THROUGH [state], for the same reason the OTP resend is not:
  /// the tab reads this state to decide what to draw, and a transient loading
  /// or error value would redraw the whole panel mid-action.
  Future<String?> subscribe(String email) async {
    final result =
        await ref.read(newsletterRepositoryProvider).subscribe(email);

    return result.fold(
      (failure) => failure.message,
      (_) {
        // Optimistic, and honest: `newsletter_subscribe` always writes
        // `pending`, never `subscribed`. Showing "subscribed" here would be a
        // lie until the confirmation link is clicked.
        state = const AsyncValue.data(NewsletterStatus.pending);
        return null;
      },
    );
  }

  Future<String?> unsubscribe() async {
    final result = await ref.read(newsletterRepositoryProvider).unsubscribe();

    return result.fold(
      (failure) => failure.message,
      (_) {
        state = const AsyncValue.data(NewsletterStatus.unsubscribed);
        return null;
      },
    );
  }
}
