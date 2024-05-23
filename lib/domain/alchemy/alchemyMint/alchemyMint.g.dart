// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alchemyMint.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Mint _$MintFromJson(Map<String, dynamic> json) => Mint(
      mintAddress: json['mintAddress'] as String?,
      blockNumber: (json['blockNumber'] as num?)?.toInt(),
      timestamp: const DateIso8601NullSafetyJsonConverter()
          .fromJson(json['timestamp'] as String?),
      transactionHash: json['transactionHash'] as String?,
    );

Map<String, dynamic> _$MintToJson(Mint instance) => <String, dynamic>{
      'mintAddress': instance.mintAddress,
      'blockNumber': instance.blockNumber,
      'timestamp':
          const DateIso8601NullSafetyJsonConverter().toJson(instance.timestamp),
      'transactionHash': instance.transactionHash,
    };
