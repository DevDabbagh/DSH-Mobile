import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Prints every call the app makes to Supabase — and nothing at all in a
/// release build.
///
/// WHY AT THE HTTP CLIENT AND NOT IN THE DATASOURCES
///
/// `Supabase.initialize` takes an `httpClient`, and everything the SDK does
/// goes through it: PostgREST queries, sign-in, token refresh, storage reads,
/// Edge Function calls. One class here sees all of it. The alternative was a
/// log line in each of eight datasources, which would drift the moment
/// somebody added a ninth — and would still miss the auth traffic, which is
/// exactly the traffic that goes wrong.
///
/// WHY IT IS COMPILE-TIME DEAD IN RELEASE
///
/// The wrapper is only installed in [maybeWrap] when [kDebugMode] is true, and
/// every method below is additionally guarded. Dart's tree shaker removes code
/// behind a `kDebugMode` constant in a release build, so this costs a release
/// APK nothing — no branch, no string building, no bytes.
///
/// That matters for more than size. Request logs contain access tokens and
/// email addresses; a release build that printed them would be writing user
/// credentials into the device log, readable by anything with log access.
class NetLogger extends http.BaseClient {
  final http.Client _inner;

  NetLogger(this._inner);

  /// The logging client in debug, the plain one in release.
  ///
  /// Returns null in release so the caller can pass null straight to
  /// `Supabase.initialize` and let the SDK use its own default client.
  static http.Client? maybeWrap() {
    if (!kDebugMode) return null;
    return NetLogger(http.Client());
  }

  /// Bodies are truncated to this. A film list with poster URLs runs to tens
  /// of kilobytes, and a console that scrolls past the useful part is the same
  /// as no console.
  static const _maxBody = 1200;

  /// Header values that must never be printed, even in debug.
  ///
  /// A JWT in the console ends up in screenshots, in pasted bug reports, and
  /// in whatever the terminal scrollback gets copied into. The name of the
  /// header is useful; its value never is.
  static const _secretHeaders = {
    'authorization',
    'apikey',
    'x-client-info',
    'cookie',
    'set-cookie',
  };

  /// Body fields to blank out before printing.
  static const _secretFields = {
    'password',
    'new_password',
    'access_token',
    'refresh_token',
    'token',
    'id_token',
    'provider_token',
  };

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (!kDebugMode) return _inner.send(request);

    final started = DateTime.now();
    final label = '${request.method} ${_shortPath(request.url)}';

    _line('→ $label', request.url.toString());

    if (request is http.Request && request.body.isNotEmpty) {
      _line('  body', _redactBody(request.body));
    }

    try {
      final response = await _inner.send(request);
      final ms = DateTime.now().difference(started).inMilliseconds;

      // Read the body to log it, then hand back a response that still has
      // one — a stream can only be consumed once, and consuming it here
      // without replacing it would leave the SDK with nothing to parse.
      final bytes = await response.stream.toBytes();
      final ok = response.statusCode >= 200 && response.statusCode < 300;

      _line(
        '${ok ? '✓' : '✗'} ${response.statusCode} $label',
        '${ms}ms',
      );

      // Successful bodies are noise; failed ones are the whole point. A 400
      // from PostgREST carries the actual reason — a missing column, a policy
      // that refused — and that message is what turns half an hour of
      // guessing into a one-line fix.
      if (!ok && bytes.isNotEmpty) {
        _line('  error', _redactBody(utf8.decode(bytes, allowMalformed: true)));
      }

      return http.StreamedResponse(
        Stream.value(bytes),
        response.statusCode,
        contentLength: bytes.length,
        request: response.request,
        headers: response.headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
      );
    } catch (e) {
      // A network failure never reaches the status-code branch above, so
      // without this the log would simply stop mid-request — which reads like
      // the app hung rather than the connection dropped.
      _line('✗ $label', 'threw: $e');
      rethrow;
    }
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }

  /// `/rest/v1/films?select=…` rather than the full project URL, which is the
  /// same eighty characters on every single line.
  String _shortPath(Uri url) {
    final path =
        url.path.replaceFirst('/rest/v1', '').replaceFirst('/auth/v1', ' auth');
    final query = url.query.isEmpty ? '' : '?${_trim(url.query, 160)}';
    return '$path$query';
  }

  /// Blanks out anything sensitive, then trims.
  String _redactBody(String body) {
    var out = body;

    for (final field in _secretFields) {
      out = out.replaceAll(
        RegExp('"$field"\\s*:\\s*"[^"]*"'),
        '"$field":"•••"',
      );
    }

    return _trim(out, _maxBody);
  }

  static String _trim(String s, int max) =>
      s.length <= max ? s : '${s.substring(0, max)}… (${s.length} chars)';

  /// `developer.log` rather than `print`: it survives long lines without the
  /// truncation Android's logcat applies at 1024 characters, and it shows up
  /// as one entry in DevTools rather than a dozen wrapped ones.
  void _line(String message, String detail) {
    developer.log(
      detail.isEmpty ? message : '$message  $detail',
      name: 'supabase',
    );
  }
}

/// Header redaction, exposed for the one place that logs headers directly.
bool isSecretHeader(String name) =>
    NetLogger._secretHeaders.contains(name.toLowerCase());
