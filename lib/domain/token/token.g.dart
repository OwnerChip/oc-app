// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Token _$TokenFromJson(Map<String, dynamic> json) => Token(
      tokenId: json['tokenId'] as String,
      mintedAt: DateTime.parse(json['mintedAt'] as String),
      collectionAddress: json['collectionAddress'] as String,
      collectionName: json['collectionName'] as String,
      collectionSymbol: json['collectionSymbol'] as String,
      hasVoucherToken: json['hasVoucherToken'] as bool,
      voucherCollection: json['voucherCollection'] as String,
      voucherTokenUri: json['voucherTokenUri'] as String,
      hasActiveOffer: json['hasActiveOffer'] as bool,
      activeOffers: (json['activeOffers'] as List<dynamic>)
          .map((e) => ActiveOffer.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TokenToJson(Token instance) => <String, dynamic>{
      'tokenId': instance.tokenId,
      'mintedAt': instance.mintedAt.toIso8601String(),
      'collectionAddress': instance.collectionAddress,
      'collectionName': instance.collectionName,
      'collectionSymbol': instance.collectionSymbol,
      'hasVoucherToken': instance.hasVoucherToken,
      'voucherCollection': instance.voucherCollection,
      'voucherTokenUri': instance.voucherTokenUri,
      'hasActiveOffer': instance.hasActiveOffer,
      'activeOffers': instance.activeOffers.map((e) => e.toJson()).toList(),
    };
