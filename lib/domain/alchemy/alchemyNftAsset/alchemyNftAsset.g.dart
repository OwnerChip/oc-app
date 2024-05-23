// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alchemyNftAsset.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AlchemyNFTAsset _$AlchemyNFTAssetFromJson(Map<String, dynamic> json) =>
    AlchemyNFTAsset(
      contract:
          AlchemyContract.fromJson(json['contract'] as Map<String, dynamic>),
      tokenId: json['tokenId'] as String,
      tokenType: json['tokenType'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      tokenUri: json['tokenUri'] as String,
      image:
          AlchemyNftAssetImage.fromJson(json['image'] as Map<String, dynamic>),
      raw: AlchemyRaw.fromJson(json['raw'] as Map<String, dynamic>),
      collection: json['collection'],
      mint: Mint.fromJson(json['mint'] as Map<String, dynamic>),
      owners: json['owners'],
      timeLastUpdated: const DateIso8601JsonConverter()
          .fromJson(json['timeLastUpdated'] as String),
      balance: (json['balance'] as num).toInt(),
      acquiredAt:
          AcquiredAt.fromJson(json['acquiredAt'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AlchemyNFTAssetToJson(AlchemyNFTAsset instance) =>
    <String, dynamic>{
      'contract': instance.contract.toJson(),
      'tokenId': instance.tokenId,
      'tokenType': instance.tokenType,
      'name': instance.name,
      'description': instance.description,
      'tokenUri': instance.tokenUri,
      'image': instance.image.toJson(),
      'raw': instance.raw.toJson(),
      'collection': instance.collection,
      'mint': instance.mint.toJson(),
      'owners': instance.owners,
      'timeLastUpdated':
          const DateIso8601JsonConverter().toJson(instance.timeLastUpdated),
      'balance': instance.balance,
      'acquiredAt': instance.acquiredAt.toJson(),
    };
