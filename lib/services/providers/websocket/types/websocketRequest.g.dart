// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'websocketRequest.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WebsocketRequest _$WebsocketRequestFromJson(Map<String, dynamic> json) =>
    WebsocketRequest(
      type: json['type'] as String,
      data: json['data'],
    );

Map<String, dynamic> _$WebsocketRequestToJson(WebsocketRequest instance) =>
    <String, dynamic>{
      'type': instance.type,
      'data': instance.data,
    };
