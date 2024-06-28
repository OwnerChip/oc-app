// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rariblePrepareOrderTransactionResponse.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RariblePrepareOrderTransactionResponse
    _$RariblePrepareOrderTransactionResponseFromJson(
            Map<String, dynamic> json) =>
        RariblePrepareOrderTransactionResponse(
          transferProxyAddress: json['transferProxyAddress'] as String,
          asset: json['asset'] as Map<String, dynamic>,
          value: json['value'] as String,
        );

Map<String, dynamic> _$RariblePrepareOrderTransactionResponseToJson(
        RariblePrepareOrderTransactionResponse instance) =>
    <String, dynamic>{
      'transferProxyAddress': instance.transferProxyAddress,
      'asset': instance.asset,
      'value': instance.value,
    };
