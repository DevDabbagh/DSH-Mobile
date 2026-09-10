import 'package:json_annotation/json_annotation.dart';

part 'base_response_model.g.dart';

/// Generic API response wrapper.
/// Backend responses follow: { "status": true, "message": "...", "data": ... }
@JsonSerializable(genericArgumentFactories: true)
class BaseResponseModel<T> {
  final bool? status;
  final String? message;
  final T? data;

  const BaseResponseModel({this.status, this.message, this.data});

  factory BaseResponseModel.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$BaseResponseModelFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$BaseResponseModelToJson(this, toJsonT);
}
