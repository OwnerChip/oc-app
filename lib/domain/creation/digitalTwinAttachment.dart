import 'package:json_annotation/json_annotation.dart';
import 'package:ownerchip_whitelabel/domain/converters/stringifyJsonConverter.dart';

part 'digitalTwinAttachment.g.dart';

@JsonSerializable(explicitToJson: true)
class DigitalTwinAttachment {
  factory DigitalTwinAttachment.fromJson(Map<String, dynamic> json) =>
      _$DigitalTwinAttachmentFromJson(json);

  Map<String, dynamic> toJson() => _$DigitalTwinAttachmentToJson(this);

  final String uid;
  final String title;
  final String? link;
  final String? contentType;
  final String? fileName;
  final int? fileSize;
  final String? fileHash;
  final String uploadedAt;
  final String creatorId;
  final String metadataId;
  final bool isPrivate;
  final String? downloadLink;

  @StringifyJsonConverter()
  final String? attachmentUuid;

  const DigitalTwinAttachment({
    required this.uid,
    required this.title,
    this.link,
    this.contentType,
    this.fileName,
    this.fileSize,
    this.fileHash,
    required this.uploadedAt,
    required this.creatorId,
    required this.metadataId,
    required this.isPrivate,
    this.downloadLink,
    this.attachmentUuid,
  });
}
