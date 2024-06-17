// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rariblePrepareOrderTransactionPayload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RariblePrepareOrderTransactionPayload
    _$RariblePrepareOrderTransactionPayloadFromJson(
            Map<String, dynamic> json) =>
        RariblePrepareOrderTransactionPayload(
          maker: json['maker'] as String,
          taker: json['taker'] as String,
          amount: json['amount'] as String,
          payouts: (json['payouts'] as List<dynamic>)
              .map((e) =>
                  RaribleRecipientPayload.fromJson(e as Map<String, dynamic>))
              .toList(),
          originFees: (json['originFees'] as List<dynamic>)
              .map((e) =>
                  RaribleRecipientPayload.fromJson(e as Map<String, dynamic>))
              .toList(),
        );

Map<String, dynamic> _$RariblePrepareOrderTransactionPayloadToJson(
        RariblePrepareOrderTransactionPayload instance) =>
    <String, dynamic>{
      'maker': instance.maker,
      'taker': instance.taker,
      'amount': instance.amount,
      'payouts': instance.payouts.map((e) => e.toJson()).toList(),
      'originFees': instance.originFees.map((e) => e.toJson()).toList(),
    };
