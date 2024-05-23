// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'raribleAssetType.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RaribleAssetType _$RaribleAssetTypeFromJson(Map<String, dynamic> json) =>
    RaribleAssetType(
      assetClass: json['assetClass'] as String,
      contract: const EthereumAddressNullsafetyJsonConverter()
          .fromJson(json['contract'] as String?),
      tokenId: json['tokenId'] == null
          ? null
          : BigInt.parse(json['tokenId'] as String),
    );

Map<String, dynamic> _$RaribleAssetTypeToJson(RaribleAssetType instance) =>
    <String, dynamic>{
      'assetClass': instance.assetClass,
      'contract': const EthereumAddressNullsafetyJsonConverter()
          .toJson(instance.contract),
      'tokenId': instance.tokenId?.toString(),
    };
