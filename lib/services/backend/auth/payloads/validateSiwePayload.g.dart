// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'validateSiwePayload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ValidateSiwePayload _$ValidateSiwePayloadFromJson(Map<String, dynamic> json) =>
    ValidateSiwePayload(
      message: json['message'] as Map<String, dynamic>,
      signature: json['signature'] as String,
    );

Map<String, dynamic> _$ValidateSiwePayloadToJson(
        ValidateSiwePayload instance) =>
    <String, dynamic>{
      'message': instance.message,
      'signature': instance.signature,
    };
