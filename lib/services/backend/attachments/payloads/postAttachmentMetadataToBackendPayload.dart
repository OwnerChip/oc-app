import 'package:json_annotation/json_annotation.dart';

part 'postAttachmentMetadataToBackendPayload.g.dart';

@JsonSerializable(explicitToJson: true)
class PostAttachmentMetadataToBackendPayload {
  factory PostAttachmentMetadataToBackendPayload.fromJson(
          Map<String, dynamic> json) =>
      _$PostAttachmentMetadataToBackendPayloadFromJson(json);

  Map<String, dynamic> toJson() =>
      _$PostAttachmentMetadataToBackendPayloadToJson(this);

  final Map<String, dynamic> auth;
  final String name;
  final String title;
  final int? fileSize;

  @JsonKey(name: "content_type")
  final String? contentType;

  @JsonKey(name: "sha256_hash")
  final String? sha256Hash;

  @JsonKey(name: 'is_private')
  final bool isPrivate;

  final String? link;

  const PostAttachmentMetadataToBackendPayload({
    required this.auth,
    required this.name,
    required this.title,
    this.fileSize,
    this.contentType,
    this.sha256Hash,
    required this.isPrivate,
    this.link,
  });
}
