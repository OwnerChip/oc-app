// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'putAttachmentMetadataToBackendPayload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PutAttachmentMetadataToBackendPayload
    _$PutAttachmentMetadataToBackendPayloadFromJson(
            Map<String, dynamic> json) =>
        PutAttachmentMetadataToBackendPayload(
          auth: json['auth'] as Map<String, dynamic>,
          uuid: json['uuid'] as String,
          isPrivate: json['is_private'] as bool,
          title: json['new_title'] as String,
          newLink: json['new_link'] as String?,
        );

Map<String, dynamic> _$PutAttachmentMetadataToBackendPayloadToJson(
        PutAttachmentMetadataToBackendPayload instance) =>
    <String, dynamic>{
      'auth': instance.auth,
      'uuid': instance.uuid,
      'is_private': instance.isPrivate,
      'new_title': instance.title,
      'new_link': instance.newLink,
    };
