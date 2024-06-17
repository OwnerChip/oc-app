// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'raribleCreateOrUpdateOrderPayload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RaribleCreateOrUpdateOrderPayload _$RaribleCreateOrUpdateOrderPayloadFromJson(
        Map<String, dynamic> json) =>
    RaribleCreateOrUpdateOrderPayload(
      type: json['@type'] as String?,
      data: json['data'] as Map<String, dynamic>,
      maker: json['maker'] as String,
      taker: json['taker'] as String?,
      make: json['make'] as Map<String, dynamic>,
      take: json['take'] as Map<String, dynamic>,
      startedAt: json['startedAt'] == null
          ? null
          : DateTime.parse(json['startedAt'] as String),
      endedAt: DateTime.parse(json['endedAt'] as String),
      salt: json['salt'] as String,
      signature: json['signature'] as String,
      blockchain: json['blockchain'] as String,
    );

Map<String, dynamic> _$RaribleCreateOrUpdateOrderPayloadToJson(
        RaribleCreateOrUpdateOrderPayload instance) =>
    <String, dynamic>{
      '@type': instance.type,
      'data': instance.data,
      'maker': instance.maker,
      'taker': instance.taker,
      'make': instance.make,
      'take': instance.take,
      'startedAt': instance.startedAt?.toIso8601String(),
      'endedAt': instance.endedAt.toIso8601String(),
      'salt': instance.salt,
      'signature': instance.signature,
      'blockchain': instance.blockchain,
    };
