// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sendCardLostPayload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SendCardLostPayload _$SendCardLostPayloadFromJson(Map<String, dynamic> json) =>
    SendCardLostPayload(
      name: json['name'] as String,
      email: json['email'] as String,
      telNr: json['telNr'] as String,
      sessionId: json['sessionId'] as String,
      chipAddress: json['chipAddress'] as String,
      chipSignature: json['chipSignature'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$SendCardLostPayloadToJson(
        SendCardLostPayload instance) =>
    <String, dynamic>{
      'name': instance.name,
      'email': instance.email,
      'telNr': instance.telNr,
      'sessionId': instance.sessionId,
      'chipAddress': instance.chipAddress,
      'chipSignature': instance.chipSignature,
    };
