// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'postAttachmentMetadataToBackendPayload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PostAttachmentMetadataToBackendPayload
    _$PostAttachmentMetadataToBackendPayloadFromJson(
            Map<String, dynamic> json) =>
        PostAttachmentMetadataToBackendPayload(
          auth: json['auth'] as Map<String, dynamic>,
          name: json['name'] as String,
          title: json['title'] as String,
          fileSize: (json['fileSize'] as num?)?.toInt(),
          contentType: json['content_type'] as String?,
          sha256Hash: json['sha256_hash'] as String?,
          isPrivate: json['is_private'] as bool,
          link: json['link'] as String?,
        );

Map<String, dynamic> _$PostAttachmentMetadataToBackendPayloadToJson(
        PostAttachmentMetadataToBackendPayload instance) =>
    <String, dynamic>{
      'auth': instance.auth,
      'name': instance.name,
      'title': instance.title,
      'fileSize': instance.fileSize,
      'content_type': instance.contentType,
      'sha256_hash': instance.sha256Hash,
      'is_private': instance.isPrivate,
      'link': instance.link,
    };
