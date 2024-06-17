// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'walletSignature.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WalletSignature _$WalletSignatureFromJson(Map<String, dynamic> json) =>
    WalletSignature(
      r: json['r'] as String,
      s: json['s'] as String,
      v: (json['v'] as num).toInt(),
    );

Map<String, dynamic> _$WalletSignatureToJson(WalletSignature instance) =>
    <String, dynamic>{
      'r': instance.r,
      's': instance.s,
      'v': instance.v,
    };
