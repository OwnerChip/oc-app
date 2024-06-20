import 'package:json_annotation/json_annotation.dart';

part 'offerItemPayload.g.dart';

@JsonSerializable(explicitToJson: true)
class OfferItemPayload {
  factory OfferItemPayload.fromJson(Map<String, dynamic> json) =>
      _$OfferItemPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$OfferItemPayloadToJson(this);

  final String tokenId;
  final String offerPrice;
  final String offerCurrency;
  final String sellerWalletAddress;
  final String sellerPayoutAddress;
  final String sellerEmail;
  final int validUntil;
  final String salt;
  final String encodedData;
  final String typedDataHash;
  final String chipSignature;
  final String marketplaceContract;
  final String offchainOfferId;

  final String offerPaymentToken;

  const OfferItemPayload({
    required this.tokenId,
    required this.offerPrice,
    required this.offerCurrency,
    required this.sellerWalletAddress,
    required this.sellerPayoutAddress,
    required this.sellerEmail,
    required this.validUntil,
    required this.salt,
    required this.encodedData,
    required this.typedDataHash,
    required this.chipSignature,
    required this.marketplaceContract,
    required this.offchainOfferId,
    required this.offerPaymentToken,
  });
}
