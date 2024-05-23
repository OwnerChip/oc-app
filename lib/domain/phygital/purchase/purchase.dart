import 'package:json_annotation/json_annotation.dart';
import 'package:ownerchip_whitelabel/domain/converters/dateIso8601JsonConverter.dart';
import 'package:ownerchip_whitelabel/domain/converters/dateIso8601NullSafetyJsonConverter.dart';
import 'package:ownerchip_whitelabel/domain/phygital/buyer/buyer.dart';
import 'package:ownerchip_whitelabel/domain/phygital/offer/offer.dart';
import 'package:ownerchip_whitelabel/domain/phygital/purchaseTokenData/purchaseTokenData.dart';
import 'package:ownerchip_whitelabel/domain/phygital/shippingInfo/shippingInfo.dart';

part 'purchase.g.dart';

@JsonSerializable(explicitToJson: true)
class Purchase {
  factory Purchase.fromJson(Map<String, dynamic> json) =>
      _$PurchaseFromJson(json);

  Map<String, dynamic> toJson() => _$PurchaseToJson(this);
  String purchaseTxHash;
  @DateIso8601JsonConverter()
  DateTime createdAt;
  bool isRedeemed;
  @DateIso8601NullSafetyJsonConverter()
  DateTime? redeemedAt;
  Buyer buyer;
  PurchaseTokenData token;
  Offer offer;
  ShippingInfo? shippingInfo;
  bool manualHandover = false;

  Purchase({
    required this.purchaseTxHash,
    required this.createdAt,
    required this.isRedeemed,
    this.redeemedAt,
    required this.buyer,
    required this.token,
    required this.offer,
    this.shippingInfo,
    this.manualHandover = false,
  });
}
