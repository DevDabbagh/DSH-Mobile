import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:dsh_mobile/app/router/app_router.dart';
import 'package:dsh_mobile/app/utils/ui_helpers.dart';

class DioExceptions implements Exception {
  late String message;

  DioExceptions.fromDioError(DioException dioError) {
    if (kDebugMode) {
      debugPrint('DioException type: ${dioError.type.name}');
    }

    switch (dioError.type) {
      case DioExceptionType.cancel:
        message = 'Request was cancelled.';
        break;
      case DioExceptionType.connectionTimeout:
        message = 'Connection timeout.';
        break;
      case DioExceptionType.receiveTimeout:
        message = 'Receive timeout.';
        break;
      case DioExceptionType.badResponse:
        if (dioError.response?.statusCode == 401) break;
        message = _extractMessage(dioError.response?.data) ??
            _handleError(dioError.response?.statusCode ?? 0);
        _showSnackBar('Error', message);
        break;
      case DioExceptionType.sendTimeout:
        message = 'Send timeout.';
        break;
      case DioExceptionType.unknown:
        message = 'Unexpected error occurred.';
        _showSnackBar('Error', message);
        break;
      default:
        message = 'Something went wrong.';
        break;
    }

    if (message.isEmpty) {
      message = 'Unexpected error occurred.';
    }
  }

  String? _extractMessage(dynamic data) {
    if (data is! Map<String, dynamic>) return null;
    final errors = data['errors'];
    if (errors is Map<String, dynamic> && errors.isNotEmpty) {
      final firstList = errors.values.first;
      if (firstList is List && firstList.isNotEmpty) {
        return firstList.first.toString();
      }
    }
    return data['message'] as String?;
  }

  String _handleError(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request.';
      case 401:
        return 'Unauthorized.';
      case 403:
        return 'Forbidden.';
      case 404:
        return 'Not found.';
      case 500:
        return 'Internal server error.';
      case 502:
        return 'Bad gateway.';
      default:
        return 'A server error occurred.';
    }
  }

  void _showSnackBar(String title, String msg) {
    if (rootNavigatorKey.currentContext != null) {
      UIHelpers.showErrorSnackBar(
          rootNavigatorKey.currentContext!, '$title: $msg');
    }
  }

  @override
  String toString() => message;
}
