import 'package:json_annotation/json_annotation.dart';

part 'fcmNotificationDigitalTwinCreationData.g.dart';

@JsonSerializable(explicitToJson: true)
class FcmNotificationDigitalTwinCreationData {
  factory FcmNotificationDigitalTwinCreationData.fromJson(
          Map<String, dynamic> json) =>
      _$FcmNotificationDigitalTwinCreationDataFromJson(json);

  Map<String, dynamic> toJson() =>
      _$FcmNotificationDigitalTwinCreationDataToJson(this);

  final String userWalletAddress;
  final String metadataId;
  final String title;
  final String imageUri;

  const FcmNotificationDigitalTwinCreationData({
    required this.metadataId,
    required this.title,
    required this.imageUri,
    required this.userWalletAddress,
  });
}
