// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'makeRaribleRequestPayload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MakeRaribleRequestPayload _$MakeRaribleRequestPayloadFromJson(
        Map<String, dynamic> json) =>
    MakeRaribleRequestPayload(
      config:
          RaribleRequestConfig.fromJson(json['config'] as Map<String, dynamic>),
      chainId: (json['chainId'] as num).toInt(),
    );

Map<String, dynamic> _$MakeRaribleRequestPayloadToJson(
        MakeRaribleRequestPayload instance) =>
    <String, dynamic>{
      'config': instance.config.toJson(),
      'chainId': instance.chainId,
    };
