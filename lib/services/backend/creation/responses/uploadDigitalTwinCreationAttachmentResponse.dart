import 'package:json_annotation/json_annotation.dart';

part 'uploadDigitalTwinCreationAttachmentResponse.g.dart';

@JsonSerializable(explicitToJson: true)
class UploadDigitalTwinCreationAttachmentResponse {
  factory UploadDigitalTwinCreationAttachmentResponse.fromJson(
          Map<String, dynamic> json) =>
      _$UploadDigitalTwinCreationAttachmentResponseFromJson(json);

  Map<String, dynamic> toJson() =>
      _$UploadDigitalTwinCreationAttachmentResponseToJson(this);

  final String uid;
  final String? url;

  const UploadDigitalTwinCreationAttachmentResponse({
    required this.uid,
    this.url,
  });
}
