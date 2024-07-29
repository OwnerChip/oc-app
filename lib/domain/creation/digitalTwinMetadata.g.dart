// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'digitalTwinMetadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DigitalTwinMetadata _$DigitalTwinMetadataFromJson(Map<String, dynamic> json) =>
    DigitalTwinMetadata(
      id: json['id'] as String,
      collectionId: json['collectionId'] as String,
      collection:
          OCCollection.fromJson(json['collection'] as Map<String, dynamic>),
      creatorId: json['creatorId'] as String,
      twinTokenMetadataCID: json['twinTokenMetadataCID'] as String?,
      voucherTokenMetadataCID: json['voucherTokenMetadataCID'] as String?,
      imageCID: json['imageCID'] as String?,
      imageLink: json['imageLink'] as String?,
      traits: (json['traits'] as List<dynamic>)
          .map((e) => DigitalTwinTrait.fromJson(e as Map<String, dynamic>))
          .toList(),
      title: json['title'] as String,
      description: json['description'] as String,
      status: $enumDecode(
          _$DigitalTwinCreationMetadataStatusEnumMap, json['status']),
      createdAt:
          const DateTimeJsonConverter().fromJson(json['createdAt'] as String),
      tokenId: json['tokenId'] as String?,
    );

Map<String, dynamic> _$DigitalTwinMetadataToJson(
        DigitalTwinMetadata instance) =>
    <String, dynamic>{
      'id': instance.id,
      'collectionId': instance.collectionId,
      'collection': instance.collection.toJson(),
      'creatorId': instance.creatorId,
      'imageCID': instance.imageCID,
      'twinTokenMetadataCID': instance.twinTokenMetadataCID,
      'voucherTokenMetadataCID': instance.voucherTokenMetadataCID,
      'traits': instance.traits.map((e) => e.toJson()).toList(),
      'title': instance.title,
      'description': instance.description,
      'imageLink': instance.imageLink,
      'status': _$DigitalTwinCreationMetadataStatusEnumMap[instance.status]!,
      'createdAt': const DateTimeJsonConverter().toJson(instance.createdAt),
      'tokenId': instance.tokenId,
    };

const _$DigitalTwinCreationMetadataStatusEnumMap = {
  DigitalTwinCreationMetadataStatus.pending: 'PENDING',
  DigitalTwinCreationMetadataStatus.draft: 'DRAFT',
  DigitalTwinCreationMetadataStatus.minted: 'MINTED',
  DigitalTwinCreationMetadataStatus.toBeBurned: 'TO_BE_BURNED',
  DigitalTwinCreationMetadataStatus.burned: 'BURNED',
};
