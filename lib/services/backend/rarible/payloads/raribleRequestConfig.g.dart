// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'raribleRequestConfig.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RaribleRequestConfig _$RaribleRequestConfigFromJson(
        Map<String, dynamic> json) =>
    RaribleRequestConfig(
      method: json['method'] as String,
      endpoint: json['endpoint'] as String,
      body: json['body'] as Map<String, dynamic>,
      headers: Map<String, String>.from(json['headers'] as Map),
    );

Map<String, dynamic> _$RaribleRequestConfigToJson(
        RaribleRequestConfig instance) =>
    <String, dynamic>{
      'method': instance.method,
      'endpoint': instance.endpoint,
      'body': instance.body,
      'headers': instance.headers,
    };
