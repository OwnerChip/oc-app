// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'walletType.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WalletType _$WalletTypeFromJson(Map<String, dynamic> json) => WalletType(
      json['name'] as String,
      json['iconUri'] as String,
      $enumDecode(_$EWalletTypeEnumMap, json['type']),
    );

Map<String, dynamic> _$WalletTypeToJson(WalletType instance) =>
    <String, dynamic>{
      'name': instance.name,
      'iconUri': instance.iconUri,
      'type': _$EWalletTypeEnumMap[instance.type]!,
    };

const _$EWalletTypeEnumMap = {
  EWalletType.ownerCard: 'ownerCard',
  EWalletType.walletConnect: 'walletConnect',
  EWalletType.web3auth: 'web3auth',
};
