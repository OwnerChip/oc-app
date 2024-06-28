import 'package:json_annotation/json_annotation.dart';

part 'putAttachmentMetadataToBackendPayload.g.dart';

@JsonSerializable(explicitToJson: true)
class PutAttachmentMetadataToBackendPayload {
  factory PutAttachmentMetadataToBackendPayload.fromJson(
          Map<String, dynamic> json) =>
      _$PutAttachmentMetadataToBackendPayloadFromJson(json);

  Map<String, dynamic> toJson() =>
      _$PutAttachmentMetadataToBackendPayloadToJson(this);

  final Map<String, dynamic> auth;
  final String uuid;

  @JsonKey(name: "is_private")
  final bool isPrivate;

  @JsonKey(name: "new_title")
  final String title;

  @JsonKey(name: "new_link")
  final String? newLink;

  const PutAttachmentMetadataToBackendPayload({
    required this.auth,
    required this.uuid,
    required this.isPrivate,
    required this.title,
    this.newLink,
  });
}
