// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qrcodeLoginConfirmPayload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QrCodeLoginConfirmPayload _$QrCodeLoginConfirmPayloadFromJson(
        Map<String, dynamic> json) =>
    QrCodeLoginConfirmPayload(
      sessionId: json['sessionId'] as String,
      socketId: json['socketId'] as String,
    );

Map<String, dynamic> _$QrCodeLoginConfirmPayloadToJson(
        QrCodeLoginConfirmPayload instance) =>
    <String, dynamic>{
      'sessionId': instance.sessionId,
      'socketId': instance.socketId,
    };
