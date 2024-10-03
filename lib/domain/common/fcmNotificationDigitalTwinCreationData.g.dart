// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fcmNotificationDigitalTwinCreationData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FcmNotificationDigitalTwinCreationData
    _$FcmNotificationDigitalTwinCreationDataFromJson(
            Map<String, dynamic> json) =>
        FcmNotificationDigitalTwinCreationData(
          metadataId: json['metadataId'] as String,
          title: json['title'] as String,
          imageUri: json['imageUri'] as String,
          userWalletAddress: json['userWalletAddress'] as String,
        );

Map<String, dynamic> _$FcmNotificationDigitalTwinCreationDataToJson(
        FcmNotificationDigitalTwinCreationData instance) =>
    <String, dynamic>{
      'userWalletAddress': instance.userWalletAddress,
      'metadataId': instance.metadataId,
      'title': instance.title,
      'imageUri': instance.imageUri,
    };
