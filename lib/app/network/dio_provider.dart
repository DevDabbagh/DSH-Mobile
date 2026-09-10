import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio_http_formatter/dio_http_formatter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dsh_mobile/app/config/constants.dart';
import 'package:dsh_mobile/app/network/dio_exceptions.dart';
import 'package:dsh_mobile/app/providers/shared_prefs_provider.dart';
import 'package:dsh_mobile/app/router/app_router.dart';
import 'package:dsh_mobile/app/utils/ui_helpers.dart';

part 'dio_provider.g.dart';

bool _isNavigatingToLogin = false;

@riverpod
Dio dio(Ref ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Constants.baseUrl,
      connectTimeout: Constants.connectionTimeout,
      receiveTimeout: Constants.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'PLATFORM_NAME': Platform.isAndroid ? 'android' : 'ios',
      },
    ),
  );

  // Pretty-print HTTP logs only in debug builds
  if (kDebugMode) {
    dio.interceptors.add(HttpFormatter());
  }

  // Auth Interceptor
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final prefsHelper = ref.read(sharedPrefsHelperProvider);
        final token = prefsHelper.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          if (!_isNavigatingToLogin) {
            _isNavigatingToLogin = true;
            final context = rootNavigatorKey.currentContext;
            if (context != null) {
              UIHelpers.showErrorSnackBar(
                context,
                'Session expired. Please sign in again.',
              );
            }
            Future.delayed(const Duration(seconds: 3), () {
              _isNavigatingToLogin = false;
            });
          }
        } else {
          DioExceptions.fromDioError(e);
        }
        return handler.next(e);
      },
    ),
  );

  return dio;
}
