import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dsh_mobile/app/supabase/supabase_provider.dart';

part 'notification_remote_datasource.g.dart';

class NotificationRemoteDataSource {
  final SupabaseClient _client;

  NotificationRemoteDataSource(this._client);

  /// The inbox, newest first.
  ///
  /// Read from `notification_recipients` rather than `notifications`, joining
  /// outwards: the recipient row is the one carrying `read_at`, and its RLS
  /// policy scopes to `auth.uid()`. Querying `notifications` directly would
  /// return the same rows — its own policy allows only what you were sent —
  /// but would give no way to know which you had read.
  Future<List<Map<String, dynamic>>> getInbox({int limit = 50}) async {
    final rows = await _client
        .from('notification_recipients')
        .select(
            'read_at, created_at, notifications(id, title, body, image_url, route)')
        .order('created_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(rows);
  }

  /// Unread count, without pulling the rows.
  ///
  /// `CountOption.exact` costs a COUNT on the server, which is fine against
  /// the partial index on unread rows and much cheaper than shipping fifty
  /// notifications to display a number.
  Future<int> getUnreadCount() async {
    final response = await _client
        .from('notification_recipients')
        .select('id')
        .isFilter('read_at', null)
        .count(CountOption.exact);

    return response.count;
  }

  /// Marks read via the RPC, which is scoped to the caller server-side —
  /// there is no update policy that would let a client write another
  /// person's row even by accident.
  Future<int> markRead(List<String>? ids) async {
    final result = await _client.rpc(
      'mark_notifications_read',
      params: {'p_ids': ids},
    );

    return result is int ? result : 0;
  }
}

@riverpod
NotificationRemoteDataSource notificationRemoteDataSource(Ref ref) =>
    NotificationRemoteDataSource(ref.read(supabaseClientProvider));
