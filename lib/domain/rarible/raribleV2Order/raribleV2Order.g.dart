// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'raribleV2Order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RaribleV2Order _$RaribleV2OrderFromJson(Map<String, dynamic> json) =>
    RaribleV2Order(
      data: RaribleDataObject.fromJson(json['data'] as Map<String, dynamic>),
      maker: const EthereumAddressJsonConverter()
          .fromJson(json['maker'] as String),
      make:
          RaribleOrderFormAsset.fromJson(json['make'] as Map<String, dynamic>),
      take:
          RaribleOrderFormAsset.fromJson(json['take'] as Map<String, dynamic>),
      salt: BigInt.parse(json['salt'] as String),
      start: (json['start'] as num).toInt(),
      end: (json['end'] as num).toInt(),
      signature: json['signature'] as String,
    );

Map<String, dynamic> _$RaribleV2OrderToJson(RaribleV2Order instance) =>
    <String, dynamic>{
      'data': instance.data.toJson(),
      'maker': const EthereumAddressJsonConverter().toJson(instance.maker),
      'make': instance.make.toJson(),
      'take': instance.take.toJson(),
      'salt': instance.salt.toString(),
      'start': instance.start,
      'end': instance.end,
      'signature': instance.signature,
    };
