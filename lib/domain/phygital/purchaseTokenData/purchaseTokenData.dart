import 'package:json_annotation/json_annotation.dart';
import 'package:ownerchip_whitelabel/domain/converters/bigintJsonConverter.dart';
import 'package:ownerchip_whitelabel/domain/converters/dateIso8601JsonConverter.dart';

part 'purchaseTokenData.g.dart';

@JsonSerializable(explicitToJson: true)
class PurchaseTokenData {
  factory PurchaseTokenData.fromJson(Map<String, dynamic> json) =>
      _$PurchaseTokenDataFromJson(json);

  Map<String, dynamic> toJson() => _$PurchaseTokenDataToJson(this);

  @BigIntJsonConverter()
  BigInt id;

  @DateIso8601JsonConverter()
  DateTime createdAt;

  dynamic recoverySignature;
  String voucherTokenUri;
  bool hasVoucherToken;

  PurchaseTokenData({
    required this.id,
    required this.createdAt,
    this.recoverySignature,
    required this.voucherTokenUri,
    required this.hasVoucherToken,
  });
}
