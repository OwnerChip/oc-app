// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activeOffer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActiveOffer _$ActiveOfferFromJson(Map<String, dynamic> json) => ActiveOffer(
      offerHash: json['offer_hash'] as String,
      offerPrice: json['offer_price'] as String,
      offerCurrency: json['offer_currency'] as String,
      sellerEmail: json['seller_email'] as String,
      sellerAddress: json['seller_address'] as String,
      sellerPayoutAddress: json['seller_payout_address'] as String,
      createdAt: const DateIso8601JsonConverter()
          .fromJson(json['created_at'] as String),
      validUntil: (json['valid_until'] as num).toInt(),
      encodedData: json['encoded_data'] as String,
      marketplaceContract: json['marketplace_contract'] as String,
      isCancelled: json['is_cancelled'] as bool,
      offchainOfferId: json['offchain_id'] as String,
    );

Map<String, dynamic> _$ActiveOfferToJson(ActiveOffer instance) =>
    <String, dynamic>{
      'offer_hash': instance.offerHash,
      'offer_price': instance.offerPrice,
      'offer_currency': instance.offerCurrency,
      'seller_email': instance.sellerEmail,
      'seller_address': instance.sellerAddress,
      'seller_payout_address': instance.sellerPayoutAddress,
      'created_at': const DateIso8601JsonConverter().toJson(instance.createdAt),
      'valid_until': instance.validUntil,
      'encoded_data': instance.encodedData,
      'marketplace_contract': instance.marketplaceContract,
      'is_cancelled': instance.isCancelled,
      'offchain_id': instance.offchainOfferId,
    };
