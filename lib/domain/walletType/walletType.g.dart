// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'walletType.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WalletType _$WalletTypeFromJson(Map<String, dynamic> json) => WalletType(
      json['name'] as String,
      json['iconUri'] as String,
      const EWalletTypeJsonConverter().fromJson((json['type'] as num).toInt()),
    );

Map<String, dynamic> _$WalletTypeToJson(WalletType instance) =>
    <String, dynamic>{
      'name': instance.name,
      'iconUri': instance.iconUri,
      'type': const EWalletTypeJsonConverter().toJson(instance.type),
    };
