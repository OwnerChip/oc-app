// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offerItemInputData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OfferItemInputData _$OfferItemInputDataFromJson(Map<String, dynamic> json) =>
    OfferItemInputData(
      tokenId: json['tokenId'] as String,
      offerPrice: json['offerPrice'] as String,
      offerCurrency: json['offerCurrency'] as String,
      sellerWalletAddress: json['sellerWalletAddress'] as String,
      sellerPayoutAddress: json['sellerPayoutAddress'] as String,
      sellerEmail: json['sellerEmail'] as String,
      validUntil: (json['validUntil'] as num).toInt(),
      salt: json['salt'] as String,
      encodedData: json['encodedData'] as String,
      typedDataHash: json['typedDataHash'] as String,
      chipSignature: json['chipSignature'] as String,
      marketplaceContract: json['marketplaceContract'] as String,
      offchainOfferId: json['offchainOfferId'] as String,
    );

Map<String, dynamic> _$OfferItemInputDataToJson(OfferItemInputData instance) =>
    <String, dynamic>{
      'tokenId': instance.tokenId,
      'offerPrice': instance.offerPrice,
      'offerCurrency': instance.offerCurrency,
      'sellerWalletAddress': instance.sellerWalletAddress,
      'sellerPayoutAddress': instance.sellerPayoutAddress,
      'sellerEmail': instance.sellerEmail,
      'validUntil': instance.validUntil,
      'salt': instance.salt,
      'encodedData': instance.encodedData,
      'typedDataHash': instance.typedDataHash,
      'chipSignature': instance.chipSignature,
      'marketplaceContract': instance.marketplaceContract,
      'offchainOfferId': instance.offchainOfferId,
    };
