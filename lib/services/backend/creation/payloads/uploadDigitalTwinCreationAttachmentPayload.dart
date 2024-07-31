import 'package:json_annotation/json_annotation.dart';

part 'uploadDigitalTwinCreationAttachmentPayload.g.dart';

@JsonSerializable(explicitToJson: true)
class UploadDigitalTwinCreationAttachmentPayload {
  factory UploadDigitalTwinCreationAttachmentPayload.fromJson(
          Map<String, dynamic> json) =>
      _$UploadDigitalTwinCreationAttachmentPayloadFromJson(json);

  Map<String, dynamic> toJson() =>
      _$UploadDigitalTwinCreationAttachmentPayloadToJson(this);
  final String title;
  final String? contentType;
  final bool isPrivate;
  final int? fileSize;
  final String? fileName;
  final String? fileHash;
  final String? link;

  const UploadDigitalTwinCreationAttachmentPayload({
    required this.title,
    this.contentType,
    required this.isPrivate,
    this.fileSize,
    this.fileName,
    this.fileHash,
    this.link,
  });
}
