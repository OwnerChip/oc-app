// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alchemyAcquiredAt.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AcquiredAt _$AcquiredAtFromJson(Map<String, dynamic> json) => AcquiredAt(
      blockTimestamp: const DateIso8601NullSafetyJsonConverter()
          .fromJson(json['blockTimestamp'] as String?),
      blockNumber: (json['blockNumber'] as num?)?.toInt(),
    );

Map<String, dynamic> _$AcquiredAtToJson(AcquiredAt instance) =>
    <String, dynamic>{
      'blockTimestamp': const DateIso8601NullSafetyJsonConverter()
          .toJson(instance.blockTimestamp),
      'blockNumber': instance.blockNumber,
    };
