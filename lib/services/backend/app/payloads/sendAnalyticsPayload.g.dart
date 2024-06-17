// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sendAnalyticsPayload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SendAnalyticsPayload _$SendAnalyticsPayloadFromJson(
        Map<String, dynamic> json) =>
    SendAnalyticsPayload(
      caseId: json['case_id'] as String,
      description: json['description'] as String,
      type: json['type'] as String,
      tags: json['tags'] as String?,
    );

Map<String, dynamic> _$SendAnalyticsPayloadToJson(
        SendAnalyticsPayload instance) =>
    <String, dynamic>{
      'case_id': instance.caseId,
      'description': instance.description,
      'type': instance.type,
      'tags': instance.tags,
    };
