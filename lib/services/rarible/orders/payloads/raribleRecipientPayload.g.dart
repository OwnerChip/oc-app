// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'raribleRecipientPayload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RaribleRecipientPayload _$RaribleRecipientPayloadFromJson(
        Map<String, dynamic> json) =>
    RaribleRecipientPayload(
      account: json['account'] as String,
      value: (json['value'] as num).toInt(),
    );

Map<String, dynamic> _$RaribleRecipientPayloadToJson(
        RaribleRecipientPayload instance) =>
    <String, dynamic>{
      'account': instance.account,
      'value': instance.value,
    };
