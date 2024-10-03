// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fcm_token.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FCMToken _$FCMTokenFromJson(Map<String, dynamic> json) => FCMToken(
      id: (json['id'] as num).toInt(),
      token: json['token'] as String,
      address: json['address'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$FCMTokenToJson(FCMToken instance) => <String, dynamic>{
      'id': instance.id,
      'token': instance.token,
      'address': instance.address,
      'timestamp': instance.timestamp.toIso8601String(),
    };
