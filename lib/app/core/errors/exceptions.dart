/// Thrown when a server request fails.
class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException(this.message, {this.statusCode});
}

/// Thrown when a local cache operation fails.
class CacheException implements Exception {
  final String message;

  const CacheException(this.message);
}
