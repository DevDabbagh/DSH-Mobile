import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dsh_mobile/app/core/errors/failures.dart';

/// Turns Supabase and transport errors into a [Failure].
///
/// The counterpart to DioExceptions on the REST path. Repositories call this
/// so the presentation layer only ever sees a Failure, never a Postgrest type.
class SupabaseExceptions {
  SupabaseExceptions._();

  static Failure toFailure(Object error) {
    if (error is PostgrestException) {
      // 42501 is Postgres' insufficient_privilege, which on this project
      // always means an RLS policy refused the row rather than a bug.
      if (error.code == '42501') {
        return const ServerFailure('You do not have access to this content.');
      }
      return ServerFailure(
        error.message.isNotEmpty ? error.message : 'Database error',
        statusCode: int.tryParse(error.code ?? ''),
      );
    }

    if (error is AuthException) {
      return ServerFailure(error.message);
    }

    if (error is StorageException) {
      return ServerFailure(error.message);
    }

    // No connection at all — worth separating so the UI can say "check your
    // connection" rather than blaming the server.
    if (error is SocketException || error is HttpException) {
      return const NetworkFailure('No internet connection.');
    }

    return const ServerFailure('Something went wrong.');
  }
}
