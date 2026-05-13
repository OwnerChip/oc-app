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
      imageCID: json['imageCID'] as String?,
      imageLink: json['imageLink'] as String?,
      traits: (json['traits'] as List<dynamic>)
          .map((e) => DigitalTwinTrait.fromJson(e as Map<String, dynamic>))
          .toList(),
      title: json['title'] as String,
      description: json['description'] as String,
      status: $enumDecode(
          _$DigitalTwinCreationMetadataStatusEnumMap, json['status'],
          unknownValue: DigitalTwinCreationMetadataStatus.unknown),
      createdAt:
          const DateTimeJsonConverter().fromJson(json['createdAt'] as String),
      tokenId: json['tokenId'] as String?,
      type: $enumDecode(_$DigitalTwinCreationTypeEnumMap, json['type'],
          unknownValue: DigitalTwinCreationType.single),
      serialStartNumber: (json['serialStartNumber'] as num?)?.toInt(),
      quantity: (json['quantity'] as num?)?.toInt(),
      totalActiveSeriesItems: (json['totalActiveSeriesItems'] as num?)?.toInt(),
      parentUid: json['parentUid'] as String?,
      children: (json['children'] as List<dynamic>?)
          ?.map((e) => DigitalTwinMetadata.fromJson(e as Map<String, dynamic>))
          .toList(),
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
      'traits': instance.traits.map((e) => e.toJson()).toList(),
      'title': instance.title,
      'description': instance.description,
      'imageLink': instance.imageLink,
      'status': _$DigitalTwinCreationMetadataStatusEnumMap[instance.status]!,
      'createdAt': const DateTimeJsonConverter().toJson(instance.createdAt),
      'tokenId': instance.tokenId,
      'type': _$DigitalTwinCreationTypeEnumMap[instance.type]!,
      'serialStartNumber': instance.serialStartNumber,
      'quantity': instance.quantity,
      'totalActiveSeriesItems': instance.totalActiveSeriesItems,
      'parentUid': instance.parentUid,
      'children': instance.children?.map((e) => e.toJson()).toList(),
    };

const _$DigitalTwinCreationMetadataStatusEnumMap = {
  DigitalTwinCreationMetadataStatus.pending: 'PENDING',
  DigitalTwinCreationMetadataStatus.draft: 'DRAFT',
  DigitalTwinCreationMetadataStatus.minted: 'MINTED',
  DigitalTwinCreationMetadataStatus.toBeBurned: 'TO_BE_BURNED',
  DigitalTwinCreationMetadataStatus.toBeTransferred: 'TO_BE_TRANSFERRED',
  DigitalTwinCreationMetadataStatus.burned: 'BURNED',
  DigitalTwinCreationMetadataStatus.unknown: 'UNKNOWN',
};

const _$DigitalTwinCreationTypeEnumMap = {
  DigitalTwinCreationType.single: 'SINGLE',
  DigitalTwinCreationType.multiple: 'MULTIPLE',
  DigitalTwinCreationType.multiSerialItem: 'MULTI_SERIAL_ITEM',
};
