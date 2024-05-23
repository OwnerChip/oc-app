// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rariblePayout.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RariblePayout _$RariblePayoutFromJson(Map<String, dynamic> json) =>
    RariblePayout(
      account: const EthereumAddressJsonConverter()
          .fromJson(json['account'] as String),
      value: (json['value'] as num).toInt(),
    );

Map<String, dynamic> _$RariblePayoutToJson(RariblePayout instance) =>
    <String, dynamic>{
      'account': const EthereumAddressJsonConverter().toJson(instance.account),
      'value': instance.value,
    };
