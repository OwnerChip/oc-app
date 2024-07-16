// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backendPaginationResponse.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BackendPaginationResponse<T> _$BackendPaginationResponseFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) =>
    BackendPaginationResponse<T>(
      data: (json['data'] as List<dynamic>).map(fromJsonT).toList(),
      page: (json['page'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      total: (json['total'] as num).toInt(),
      totalPages: (json['totalPages'] as num).toInt(),
    );

Map<String, dynamic> _$BackendPaginationResponseToJson<T>(
  BackendPaginationResponse<T> instance,
  Object? Function(T value) toJsonT,
) =>
    <String, dynamic>{
      'data': instance.data.map(toJsonT).toList(),
      'page': instance.page,
      'limit': instance.limit,
      'total': instance.total,
      'totalPages': instance.totalPages,
    };
