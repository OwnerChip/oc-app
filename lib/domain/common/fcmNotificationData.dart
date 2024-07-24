import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:ownerchip_whitelabel/domain/common/fcmNotificationDigitalTwinCreationData.dart';

part 'fcmNotificationData.g.dart';

@JsonSerializable(
  explicitToJson: true,
)
class FCMNotificationData {
  factory FCMNotificationData.fromJson(Map<String, dynamic> json) =>
      _$FCMNotificationDataFromJson(json);

  Map<String, dynamic> toJson() => _$FCMNotificationDataToJson(this);

  final String type;
  final String json;

  bool get isDigitalTwinCreation => type == "DIGITAL_TWIN_CREATION";

  decodeAsDigitalTwinCreation() {
    return FcmNotificationDigitalTwinCreationData.fromJson(jsonDecode(json));
  }

  const FCMNotificationData({
    required this.type,
    required this.json,
  });
}
