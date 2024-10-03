import 'package:json_annotation/json_annotation.dart';

part 'backendPaginationResponse.g.dart';

@JsonSerializable(explicitToJson: true, genericArgumentFactories: true)
class BackendPaginationResponse<T> {
  factory BackendPaginationResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$BackendPaginationResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(
    Object? Function(T value) toJsonT,
  ) =>
      _$BackendPaginationResponseToJson(this, toJsonT);
  final List<T> data;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasNextPage => page < totalPages;

  bool get isEnd => page == totalPages;

  bool get isStart => page == 1;

  bool get hasPreviousPage => page > 1;

  bool get isEmpty => data.isEmpty;

  bool get isNotEmpty => data.isNotEmpty;

  const BackendPaginationResponse({
    required this.data,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });
}
