// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Offer _$OfferFromJson(Map<String, dynamic> json) => Offer(
      offerHash: json['offerHash'] as String,
      offerPrice: json['offerPrice'] as String,
      offerCurrency: json['offerCurrency'] as String,
      sellerEmail: json['sellerEmail'] as String,
      sellerAddress: json['sellerAddress'] as String,
      sellerPayoutAddress: json['sellerPayoutAddress'] as String,
      createdAt: const DateIso8601JsonConverter()
          .fromJson(json['createdAt'] as String),
      validUntil: (json['validUntil'] as num).toInt(),
      encodedData: json['encodedData'] as String,
      marketplaceContract: json['marketplaceContract'] as String,
      isCancelled: json['isCancelled'] as bool,
      isFilled: json['isFilled'] as bool,
    );

Map<String, dynamic> _$OfferToJson(Offer instance) => <String, dynamic>{
      'offerHash': instance.offerHash,
      'offerPrice': instance.offerPrice,
      'offerCurrency': instance.offerCurrency,
      'sellerEmail': instance.sellerEmail,
      'sellerAddress': instance.sellerAddress,
      'sellerPayoutAddress': instance.sellerPayoutAddress,
      'createdAt': const DateIso8601JsonConverter().toJson(instance.createdAt),
      'validUntil': instance.validUntil,
      'encodedData': instance.encodedData,
      'marketplaceContract': instance.marketplaceContract,
      'isCancelled': instance.isCancelled,
      'isFilled': instance.isFilled,
    };
