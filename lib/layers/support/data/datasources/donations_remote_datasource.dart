import 'package:dio/dio.dart';
// `Ref` lives here, not in riverpod_annotation.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dsh_mobile/app/config/site_config.dart';

part 'donations_remote_datasource.g.dart';

/// Talks to the website's Stripe routes.
///
/// This is the one part of the app that is not Supabase, and it has to be: the
/// Stripe secret key lives on the server, so only the server can create a
/// Checkout session. The app asks for a URL and opens it.
///
/// WHY IT BUILDS ITS OWN DIO
///
/// The shared `dioProvider` attaches the user's DSH bearer token to every
/// request and, on a 401, shows "session expired" and pushes them to sign in.
/// Both are wrong here. The token belongs to Supabase, not to the website, and
/// sending it to a third host leaks it; and a 401 from a payment endpoint must
/// not sign a donor out of the app. So this datasource uses a plain client
/// with no interceptors, pointed at the site.
class DonationsRemoteDataSource {
  final Dio _dio;

  DonationsRemoteDataSource(this._dio);

  /// Creates a Checkout session. Returns the decoded body.
  ///
  /// The amount is sent, the currency is not — the route pins it to EUR on
  /// purpose, so that a client cannot cause a conversion fee by naming another.
  Future<Map<String, dynamic>> createCheckoutSession({
    required String mode,
    required double amount,
    required String source,
    String? projectType,
    String? projectSlug,
    String? projectTitle,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      SiteConfig.checkoutEndpoint,
      data: {
        'mode': mode,
        'amount': amount,
        // Which platform the gift came from. Stated here because it has to
        // ride on the Stripe session: the donation is often filed by the
        // webhook, which is a call from Stripe with no device to inspect.
        'source': source,
        if (projectType != null) 'projectType': projectType,
        if (projectSlug != null) 'projectSlug': projectSlug,
        if (projectTitle != null) 'projectTitle': projectTitle,
      },
    );

    return res.data ?? const {};
  }

  /// `{ "mode": "test" | "live" }`.
  Future<Map<String, dynamic>> getStripeMode() async {
    final res =
        await _dio.get<Map<String, dynamic>>(SiteConfig.stripeModeEndpoint);
    return res.data ?? const {};
  }

  /// Verifies a finished session — and records the donation as a side effect.
  Future<Map<String, dynamic>> getSession(String sessionId) async {
    final res = await _dio.get<Map<String, dynamic>>(
      SiteConfig.sessionEndpoint,
      queryParameters: {'session_id': sessionId},
    );
    return res.data ?? const {};
  }

  /// Files the donor's name against the gift, or marks it anonymous.
  Future<Map<String, dynamic>> claim({
    required String sessionId,
    required bool anonymous,
    String? name,
    String? email,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      SiteConfig.claimEndpoint,
      data: {
        'sessionId': sessionId,
        'anonymous': anonymous,
        if (name != null) 'name': name,
        if (email != null) 'email': email,
      },
    );
    return res.data ?? const {};
  }
}

@riverpod
DonationsRemoteDataSource donationsRemoteDataSource(Ref ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      // 4xx carries the route's own error message ("The smallest amount we can
      // accept is €1"), which is worth showing. Dio would otherwise throw it
      // away as an exception before the repository could read it.
      validateStatus: (code) => code != null && code < 500,
    ),
  );

  return DonationsRemoteDataSource(dio);
}
