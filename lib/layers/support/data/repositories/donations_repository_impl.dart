import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
// `Ref` lives here, not in riverpod_annotation — a provider function that
// names the type in its signature needs this import even though the
// annotation comes from the other package.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dsh_mobile/app/core/errors/failures.dart';
import 'package:dsh_mobile/layers/support/data/datasources/donations_remote_datasource.dart';
import 'package:dsh_mobile/layers/support/domain/entities/donation.dart';
import 'package:dsh_mobile/layers/support/domain/repositories/donations_repository.dart';

part 'donations_repository_impl.g.dart';

class DonationsRepositoryImpl implements DonationsRepository {
  final DonationsRemoteDataSource _dataSource;

  DonationsRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, CheckoutSession>> startCheckout({
    required DonationMode mode,
    required double amount,
    FundingTarget? target,
  }) async {
    try {
      final body = await _dataSource.createCheckoutSession(
        mode: mode.wire,
        amount: amount,
        source: _platformSource,
        projectType: target?.type,
        projectSlug: target?.slug,
        projectTitle: target?.title,
      );

      final url = body['url'];
      if (url is String && url.isNotEmpty) {
        final id = body['id'];
        return Right(
          CheckoutSession(url: url, id: id is String ? id : ''),
        );
      }

      // The route answers a refusal with `{ error: "..." }`, written for a
      // donor to read — "The smallest amount we can accept is €1". Show it
      // rather than replacing it with something generic.
      final error = body['error'];
      return Left(
        ServerFailure(
          error is String && error.isNotEmpty
              ? error
              : 'Could not start checkout. Please try again.',
        ),
      );
    } catch (e) {
      return Left(_toFailure(e));
    }
  }

  @override
  Future<Either<Failure, bool?>> isTestMode() async {
    try {
      final body = await _dataSource.getStripeMode();
      final mode = body['mode'];
      if (mode == 'live') return const Right(false);
      if (mode == 'test') return const Right(true);

      // Something unexpected came back. Unknown, not "test" — see the
      // contract: a false warning on a live site is its own harm.
      return const Right(null);
    } catch (e) {
      return Left(_toFailure(e));
    }
  }

  @override
  Future<Either<Failure, DonationReceipt>> verifySession(
    String sessionId,
  ) async {
    try {
      final body = await _dataSource.getSession(sessionId);

      if (body['paid'] != true) {
        // A real answer, not an error: the session exists but was never
        // completed. The caller shows "nothing was taken", never a thank-you.
        return const Right(DonationReceipt(paid: false));
      }

      final amount = body['amount'];

      return Right(
        DonationReceipt(
          paid: true,
          amount: amount is num ? amount.toDouble() : 0,
          currency: body['currency'] is String ? body['currency'] : 'eur',
          email: body['email'] is String ? body['email'] : null,
          name: body['name'] is String ? body['name'] : null,
          mode: body['supportMode'] == 'monthly'
              ? DonationMode.monthly
              : DonationMode.oneTime,
          projectTitle:
              body['projectTitle'] is String ? body['projectTitle'] : null,
        ),
      );
    } catch (e) {
      return Left(_toFailure(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> claimDonation({
    required String sessionId,
    required bool anonymous,
    String? name,
    String? email,
  }) async {
    try {
      final body = await _dataSource.claim(
        sessionId: sessionId,
        anonymous: anonymous,
        name: name,
        email: email,
      );

      final error = body['error'];
      if (error is String && error.isNotEmpty) {
        // The route's own wording — "Enter a valid email, or continue
        // anonymously" — reads better than anything generic.
        return Left(ServerFailure(error));
      }

      return const Right(unit);
    } catch (e) {
      return Left(_toFailure(e));
    }
  }

  /// What the dashboard will show this gift as. Android and iOS are the only
  /// platforms the app ships on; anything else would be a desktop or web build
  /// of the Flutter app, which does not exist — but if one ever does, it is
  /// honestly the website's bucket rather than a silent fourth category.
  String get _platformSource {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'web';
  }

  /// The Supabase mapper does not apply here — this path is Dio against the
  /// website, and its errors are transport errors, not Postgrest ones.
  Failure _toFailure(Object e) {
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.error is SocketException) {
        return const NetworkFailure(
          'Could not reach the payment service. Check your connection.',
        );
      }
      return ServerFailure(
        'Could not start checkout. Please try again.',
        statusCode: e.response?.statusCode,
      );
    }

    if (e is SocketException) {
      return const NetworkFailure('No internet connection.');
    }

    return const ServerFailure('Could not start checkout. Please try again.');
  }
}

@riverpod
DonationsRepository donationsRepository(Ref ref) =>
    DonationsRepositoryImpl(ref.read(donationsRemoteDataSourceProvider));
