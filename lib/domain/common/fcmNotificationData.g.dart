// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fcmNotificationData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FCMNotificationData _$FCMNotificationDataFromJson(Map<String, dynamic> json) =>
    FCMNotificationData(
      type: json['type'] as String,
      json: json['json'] as String,
    );

Map<String, dynamic> _$FCMNotificationDataToJson(
        FCMNotificationData instance) =>
    <String, dynamic>{
      'type': instance.type,
      'json': instance.json,
    };
