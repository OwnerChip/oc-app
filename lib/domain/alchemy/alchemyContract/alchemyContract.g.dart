// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alchemyContract.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AlchemyContract _$AlchemyContractFromJson(Map<String, dynamic> json) =>
    AlchemyContract(
      address: json['address'] as String,
      name: json['name'] as String,
      symbol: json['symbol'] as String,
      totalSupply: json['totalSupply'],
      tokenType: json['tokenType'] as String,
      contractDeployer: json['contractDeployer'] as String,
      deployedBlockNumber: (json['deployedBlockNumber'] as num).toInt(),
      openSeaMetadata: OpenSeaMetadata.fromJson(
          json['openSeaMetadata'] as Map<String, dynamic>),
      isSpam: json['isSpam'],
      spamClassifications: json['spamClassifications'] as List<dynamic>,
    );

Map<String, dynamic> _$AlchemyContractToJson(AlchemyContract instance) =>
    <String, dynamic>{
      'address': instance.address,
      'name': instance.name,
      'symbol': instance.symbol,
      'totalSupply': instance.totalSupply,
      'tokenType': instance.tokenType,
      'contractDeployer': instance.contractDeployer,
      'deployedBlockNumber': instance.deployedBlockNumber,
      'openSeaMetadata': instance.openSeaMetadata.toJson(),
      'isSpam': instance.isSpam,
      'spamClassifications': instance.spamClassifications,
    };
