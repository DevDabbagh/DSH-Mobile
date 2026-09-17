import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dsh_mobile/app/core/errors/failures.dart';
import 'package:dsh_mobile/app/localization/locale_controller.dart';
import 'package:dsh_mobile/app/supabase/supabase_exceptions.dart';
import 'package:dsh_mobile/app/supabase/supabase_provider.dart';
import 'package:dsh_mobile/layers/auth/presentation/controllers/auth_controller.dart';
import 'package:dsh_mobile/layers/notifications/data/models/newsletter_issue_model.dart';
import 'package:dsh_mobile/layers/notifications/domain/entities/newsletter_issue.dart';
import 'package:dsh_mobile/layers/notifications/domain/repositories/newsletter_repository.dart';

part 'newsletter_repository_impl.g.dart';

/// EVERY CALL HERE IS AN RPC, AND THAT IS THE DESIGN
///
/// `newsletter_campaigns` is staff-only (043) and `newsletter_subscribers` has
/// no public policy at all (014) — not even insert. Neither table can be
/// touched from a phone, on purpose: drafts are unpublished editorial, and a
/// readable subscriber list is a harvestable one.
///
/// So the app goes through SECURITY DEFINER functions that each answer exactly
/// one question and hand back nothing else. See migration 044.
class NewsletterRepositoryImpl implements NewsletterRepository {
  final SupabaseClient _client;
  final String _locale;
  final bool _signedIn;

  NewsletterRepositoryImpl(this._client, this._locale, this._signedIn);

  @override
  Future<Either<Failure, List<NewsletterIssue>>> getArchive() async {
    try {
      final rows = await _client.rpc('newsletter_archive', params: {
        'p_limit': 30,
        'p_offset': 0,
      });

      if (rows is! List) return const Right([]);

      final issues = rows
          .whereType<Map>()
          .map((r) => NewsletterIssueModel.fromRow(
                Map<String, dynamic>.from(r),
                _locale,
              ))
          // A campaign sent with an empty subject is a record of a mistake,
          // not something to put in front of a reader.
          .where((i) => i.subject.trim().isNotEmpty)
          .toList();

      return Right(issues);
    } catch (e) {
      return Left(SupabaseExceptions.toFailure(e));
    }
  }

  @override
  Future<Either<Failure, NewsletterStatus>> myStatus() async {
    // No session, no verified address, nothing to ask about. The RPC is not
    // granted to `anon` anyway, so calling it would be an error rather than
    // an answer.
    if (!_signedIn) return const Right(NewsletterStatus.none);

    try {
      final value = await _client.rpc('my_newsletter_status');
      return Right(NewsletterStatus.fromDb(value?.toString()));
    } catch (e) {
      return Left(SupabaseExceptions.toFailure(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> subscribe(String email) async {
    try {
      await _client.rpc('newsletter_subscribe', params: {
        'p_email': email.trim(),
        'p_source': 'mobile_inbox',
        'p_consent_text':
            'Notifications → Newsletter tab: the DSH newsletter by email.',
        // See the note in the Academy card: an app cannot know its own public
        // IP, and the LAN address it could guess is evidence of nothing. A
        // blank field beats a confident wrong one in a consent record.
        'p_consent_ip': '',
      });
      return const Right(unit);
    } catch (e) {
      return Left(SupabaseExceptions.toFailure(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> unsubscribe() async {
    if (!_signedIn) return const Right(unit);

    try {
      await _client.rpc('my_newsletter_unsubscribe');
      return const Right(unit);
    } catch (e) {
      return Left(SupabaseExceptions.toFailure(e));
    }
  }
}

@riverpod
NewsletterRepository newsletterRepository(Ref ref) {
  final locale = ref.watch(localeControllerProvider).languageCode;
  final signedIn = ref.watch(currentUserProvider).valueOrNull != null;

  return NewsletterRepositoryImpl(
    ref.read(supabaseClientProvider),
    locale,
    signedIn,
  );
}
