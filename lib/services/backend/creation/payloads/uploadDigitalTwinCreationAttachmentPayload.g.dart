// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'uploadDigitalTwinCreationAttachmentPayload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UploadDigitalTwinCreationAttachmentPayload
    _$UploadDigitalTwinCreationAttachmentPayloadFromJson(
            Map<String, dynamic> json) =>
        UploadDigitalTwinCreationAttachmentPayload(
          title: json['title'] as String,
          contentType: json['contentType'] as String?,
          isPrivate: json['isPrivate'] as bool,
          fileSize: (json['fileSize'] as num?)?.toInt(),
          fileName: json['fileName'] as String?,
          fileHash: json['fileHash'] as String?,
          link: json['link'] as String?,
        );

Map<String, dynamic> _$UploadDigitalTwinCreationAttachmentPayloadToJson(
        UploadDigitalTwinCreationAttachmentPayload instance) =>
    <String, dynamic>{
      'title': instance.title,
      'contentType': instance.contentType,
      'isPrivate': instance.isPrivate,
      'fileSize': instance.fileSize,
      'fileName': instance.fileName,
      'fileHash': instance.fileHash,
      'link': instance.link,
    };
