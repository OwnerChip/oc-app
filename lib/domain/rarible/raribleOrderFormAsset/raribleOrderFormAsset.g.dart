// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'raribleOrderFormAsset.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RaribleOrderFormAsset _$RaribleOrderFormAssetFromJson(
        Map<String, dynamic> json) =>
    RaribleOrderFormAsset(
      assetType:
          RaribleAssetType.fromJson(json['assetType'] as Map<String, dynamic>),
      value: BigInt.parse(json['value'] as String),
    );

Map<String, dynamic> _$RaribleOrderFormAssetToJson(
        RaribleOrderFormAsset instance) =>
    <String, dynamic>{
      'assetType': instance.assetType.toJson(),
      'value': instance.value.toString(),
    };
