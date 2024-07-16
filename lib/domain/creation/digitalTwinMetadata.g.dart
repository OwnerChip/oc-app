// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'digitalTwinMetadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DigitalTwinMetadata _$DigitalTwinMetadataFromJson(Map<String, dynamic> json) =>
    DigitalTwinMetadata(
      id: (json['id'] as num).toInt(),
      collectionId: json['collectionId'] as String,
      collection:
          OCCollection.fromJson(json['collection'] as Map<String, dynamic>),
      creatorId: json['creatorId'] as String,
      twinTokenMetadataCID: json['twinTokenMetadataCID'] as String,
      voucherTokenMetadataCID: json['voucherTokenMetadataCID'] as String,
      traits: Map<String, String>.from(json['traits'] as Map),
      title: json['title'] as String,
      description: json['description'] as String,
      status: $enumDecode(
          _$DigitalTwinCreationMetadataStatusEnumMap, json['status']),
      createdAt:
          const DateTimeJsonConverter().fromJson(json['createdAt'] as String),
    );

Map<String, dynamic> _$DigitalTwinMetadataToJson(
        DigitalTwinMetadata instance) =>
    <String, dynamic>{
      'id': instance.id,
      'collectionId': instance.collectionId,
      'collection': instance.collection.toJson(),
      'creatorId': instance.creatorId,
      'twinTokenMetadataCID': instance.twinTokenMetadataCID,
      'voucherTokenMetadataCID': instance.voucherTokenMetadataCID,
      'traits': instance.traits,
      'title': instance.title,
      'description': instance.description,
      'status': _$DigitalTwinCreationMetadataStatusEnumMap[instance.status]!,
      'createdAt': const DateTimeJsonConverter().toJson(instance.createdAt),
    };

const _$DigitalTwinCreationMetadataStatusEnumMap = {
  DigitalTwinCreationMetadataStatus.pending: 'PENDING',
  DigitalTwinCreationMetadataStatus.rejected: 'REJECTED',
  DigitalTwinCreationMetadataStatus.minted: 'MINTED',
};
