import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dsh_mobile/app/supabase/supabase_provider.dart';

part 'read_remote_datasource.g.dart';

/// THE LISTING NEVER ASKS FOR `body`, AND THAT IS THE POINT
///
/// Two reasons, and the second is the important one.
///
/// Cheap: a body is an array of blocks and can run to tens of kilobytes. The
/// listing draws a chip, a title and two lines of excerpt. Pulling every
/// article's full text to render thirty excerpts is the kind of thing that
/// put this project over its egress allowance once already.
///
/// Correct: a subscription article's text must not reach a device that is not
/// entitled to it. Drawing a card over text the client already holds is not a
/// paywall — migration 034 says so in capitals, and the website's own article
/// page gets this wrong today. Leaving `body` out of the select means the
/// listing cannot leak it even by accident.
const _listSelect = 'id, slug, title, excerpt, tag, section, date, main_image, '
    'author, access, featured, read_minutes, related_article_ids';

/// The detail read. `body` is added conditionally — see [getArticleBySlug].
const _detailBase = '$_listSelect, main_image_caption, main_image_credit';

class ReadRemoteDataSource {
  final SupabaseClient _client;

  ReadRemoteDataSource(this._client);

  Future<List<Map<String, dynamic>>> getArticles() async {
    final rows = await _client
        .from('articles')
        .select(_listSelect)
        .eq('status', 'published')
        .order('date', ascending: false);

    return List<Map<String, dynamic>>.from(rows);
  }

  /// One article, with its body only when the reader may have it.
  ///
  /// [entitled] is decided above this layer: a free article entitles
  /// everybody, a subscription article entitles a subscriber. When it is
  /// false the row comes back without `body` and the screen shows the
  /// paywall — with nothing behind it to reveal.
  ///
  /// WHAT THIS IS NOT
  ///
  /// It is not access control on its own. A determined caller can query
  /// `articles` directly with the anon key and select `body`, because the
  /// table's RLS policy exposes published rows whole — 034 is explicit that
  /// splitting the body into its own table is the honest fix and a bigger
  /// change than that migration. Until then this app does not ship the text
  /// to a device that should not have it, which is the part this layer can
  /// actually guarantee.
  Future<Map<String, dynamic>?> getArticleBySlug(
    String slug, {
    required bool entitled,
  }) async {
    final select = entitled ? '$_detailBase, body' : _detailBase;

    final row = await _client
        .from('articles')
        .select(select)
        .eq('slug', slug)
        .eq('status', 'published')
        .maybeSingle();

    return row;
  }
}

@riverpod
ReadRemoteDataSource readRemoteDataSource(Ref ref) =>
    ReadRemoteDataSource(ref.read(supabaseClientProvider));
