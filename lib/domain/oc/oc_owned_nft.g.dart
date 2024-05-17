// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'oc_owned_nft.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OcOwnedNft _$OcOwnedNftFromJson(Map<String, dynamic> json) => OcOwnedNft(
      contract:
          AlchemyContract.fromJson(json['contract'] as Map<String, dynamic>),
      tokenId: json['tokenId'] as String,
      tokenType: json['tokenType'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      tokenUri: json['tokenUri'] as String,
      image: OcNftImage.fromJson(json['image'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$OcOwnedNftToJson(OcOwnedNft instance) =>
    <String, dynamic>{
      'contract': instance.contract.toJson(),
      'tokenId': instance.tokenId,
      'tokenType': instance.tokenType,
      'name': instance.name,
      'description': instance.description,
      'tokenUri': instance.tokenUri,
      'image': instance.image.toJson(),
    };
