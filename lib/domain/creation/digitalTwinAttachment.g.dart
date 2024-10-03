// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'digitalTwinAttachment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DigitalTwinAttachment _$DigitalTwinAttachmentFromJson(
        Map<String, dynamic> json) =>
    DigitalTwinAttachment(
      uid: json['uid'] as String,
      title: json['title'] as String,
      link: json['link'] as String?,
      contentType: json['contentType'] as String?,
      fileName: json['fileName'] as String?,
      fileSize: (json['fileSize'] as num?)?.toInt(),
      fileHash: json['fileHash'] as String?,
      uploadedAt: json['uploadedAt'] as String,
      creatorId: json['creatorId'] as String,
      metadataId: json['metadataId'] as String,
      isPrivate: json['isPrivate'] as bool,
      downloadLink: json['downloadLink'] as String?,
      attachmentUuid:
          const StringifyJsonConverter().fromJson(json['attachmentUuid']),
    );

Map<String, dynamic> _$DigitalTwinAttachmentToJson(
        DigitalTwinAttachment instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'title': instance.title,
      'link': instance.link,
      'contentType': instance.contentType,
      'fileName': instance.fileName,
      'fileSize': instance.fileSize,
      'fileHash': instance.fileHash,
      'uploadedAt': instance.uploadedAt,
      'creatorId': instance.creatorId,
      'metadataId': instance.metadataId,
      'isPrivate': instance.isPrivate,
      'downloadLink': instance.downloadLink,
      'attachmentUuid': _$JsonConverterToJson<dynamic, String>(
          instance.attachmentUuid, const StringifyJsonConverter().toJson),
    };

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);
