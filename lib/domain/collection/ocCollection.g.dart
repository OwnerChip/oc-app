// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ocCollection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OCCollection _$OCCollectionFromJson(Map<String, dynamic> json) => OCCollection(
      address: json['address'] as String,
      voucherAddress: json['voucherAddress'] as String,
      name: json['name'] as String,
      symbol: json['symbol'] as String,
      chainId: (json['chainId'] as num).toInt(),
    );

Map<String, dynamic> _$OCCollectionToJson(OCCollection instance) =>
    <String, dynamic>{
      'address': instance.address,
      'voucherAddress': instance.voucherAddress,
      'name': instance.name,
      'symbol': instance.symbol,
      'chainId': instance.chainId,
    };
