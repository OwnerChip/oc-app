// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'digitalTwinSeriesItem.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DigitalTwinSeriesItem _$DigitalTwinSeriesItemFromJson(
        Map<String, dynamic> json) =>
    DigitalTwinSeriesItem(
      uid: json['uid'] as String,
      ownerId: json['ownerId'] as String,
      imageCID: json['imageCID'] as String?,
      imageLink: json['imageLink'] as String?,
      twinTokenMetadataCID: json['twinTokenMetadataCID'] as String?,
      voucherTokenMetadataCID: json['voucherTokenMetadataCID'] as String?,
      createdAt:
          const DateTimeJsonConverter().fromJson(json['createdAt'] as String),
      mintingDate: json['mintingDate'] == null
          ? null
          : DateTime.parse(json['mintingDate'] as String),
      tokenId: json['tokenId'] as String?,
      digitalTwinTokenMetadataUID:
          json['digitalTwinTokenMetadataUID'] as String,
    );

Map<String, dynamic> _$DigitalTwinSeriesItemToJson(
        DigitalTwinSeriesItem instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'ownerId': instance.ownerId,
      'imageCID': instance.imageCID,
      'imageLink': instance.imageLink,
      'twinTokenMetadataCID': instance.twinTokenMetadataCID,
      'voucherTokenMetadataCID': instance.voucherTokenMetadataCID,
      'createdAt': const DateTimeJsonConverter().toJson(instance.createdAt),
      'mintingDate': instance.mintingDate?.toIso8601String(),
      'tokenId': instance.tokenId,
      'digitalTwinTokenMetadataUID': instance.digitalTwinTokenMetadataUID,
    };
