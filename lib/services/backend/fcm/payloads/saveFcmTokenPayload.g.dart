// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saveFcmTokenPayload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaveFCMTokenPayload _$SaveFCMTokenPayloadFromJson(Map<String, dynamic> json) =>
    SaveFCMTokenPayload(
      token: json['token'] as String,
      sessionId: json['sessionId'] as String,
    );

Map<String, dynamic> _$SaveFCMTokenPayloadToJson(
        SaveFCMTokenPayload instance) =>
    <String, dynamic>{
      'token': instance.token,
      'sessionId': instance.sessionId,
    };
