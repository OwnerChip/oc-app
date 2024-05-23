// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Purchase _$PurchaseFromJson(Map<String, dynamic> json) => Purchase(
      purchaseTxHash: json['purchaseTxHash'] as String,
      createdAt: const DateIso8601JsonConverter()
          .fromJson(json['createdAt'] as String),
      isRedeemed: json['isRedeemed'] as bool,
      redeemedAt: const DateIso8601NullSafetyJsonConverter()
          .fromJson(json['redeemedAt'] as String?),
      buyer: Buyer.fromJson(json['buyer'] as Map<String, dynamic>),
      token: PurchaseTokenData.fromJson(json['token'] as Map<String, dynamic>),
      offer: Offer.fromJson(json['offer'] as Map<String, dynamic>),
      shippingInfo: json['shippingInfo'] == null
          ? null
          : ShippingInfo.fromJson(json['shippingInfo'] as Map<String, dynamic>),
      manualHandover: json['manualHandover'] as bool? ?? false,
    );

Map<String, dynamic> _$PurchaseToJson(Purchase instance) => <String, dynamic>{
      'purchaseTxHash': instance.purchaseTxHash,
      'createdAt': const DateIso8601JsonConverter().toJson(instance.createdAt),
      'isRedeemed': instance.isRedeemed,
      'redeemedAt': const DateIso8601NullSafetyJsonConverter()
          .toJson(instance.redeemedAt),
      'buyer': instance.buyer.toJson(),
      'token': instance.token.toJson(),
      'offer': instance.offer.toJson(),
      'shippingInfo': instance.shippingInfo?.toJson(),
      'manualHandover': instance.manualHandover,
    };
