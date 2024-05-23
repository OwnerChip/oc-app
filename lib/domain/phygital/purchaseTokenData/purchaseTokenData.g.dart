// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchaseTokenData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PurchaseTokenData _$PurchaseTokenDataFromJson(Map<String, dynamic> json) =>
    PurchaseTokenData(
      id: const BigIntJsonConverter().fromJson(json['id'] as String),
      createdAt: const DateIso8601JsonConverter()
          .fromJson(json['createdAt'] as String),
      recoverySignature: json['recoverySignature'],
      voucherTokenUri: json['voucherTokenUri'] as String,
      hasVoucherToken: json['hasVoucherToken'] as bool,
    );

Map<String, dynamic> _$PurchaseTokenDataToJson(PurchaseTokenData instance) =>
    <String, dynamic>{
      'id': const BigIntJsonConverter().toJson(instance.id),
      'createdAt': const DateIso8601JsonConverter().toJson(instance.createdAt),
      'recoverySignature': instance.recoverySignature,
      'voucherTokenUri': instance.voucherTokenUri,
      'hasVoucherToken': instance.hasVoucherToken,
    };
