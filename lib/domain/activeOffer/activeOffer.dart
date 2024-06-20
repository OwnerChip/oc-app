import 'package:json_annotation/json_annotation.dart';
import 'package:ownerchip_whitelabel/domain/converters/dateIso8601JsonConverter.dart';

part 'activeOffer.g.dart';

@JsonSerializable(explicitToJson: true)
class ActiveOffer {

	factory ActiveOffer.fromJson(Map<String, dynamic> json) => _$ActiveOfferFromJson(json);
	Map<String, dynamic> toJson( ) => _$ActiveOfferToJson(this);

  ActiveOffer({
    required this.offerHash,
    required this.offerPrice,
    required this.offerCurrency,
    required this.sellerEmail,
    required this.sellerAddress,
    required this.sellerPayoutAddress,
    required this.createdAt,
    required this.validUntil,
    required this.encodedData,
    required this.marketplaceContract,
    required this.isCancelled,
    required this.offchainOfferId,
  });

  @JsonKey(name: "offer_hash")
  String offerHash;

  @JsonKey(name: "offer_price")
  String offerPrice;

  @JsonKey(name: "offer_currency")
  String offerCurrency;

  @JsonKey(name: "seller_email")
  String sellerEmail;

  @JsonKey(name: "seller_address")
  String sellerAddress;

  @JsonKey(name: "seller_payout_address")
  String sellerPayoutAddress;

  @DateIso8601JsonConverter()
  @JsonKey(name: "created_at")
  DateTime createdAt;

  @JsonKey(name: "valid_until")
  int validUntil;

  @JsonKey(name: "encoded_data")
  String encodedData;

  @JsonKey(name: "marketplace_contract")
  String marketplaceContract;

  @JsonKey(name: "is_cancelled")
  bool isCancelled;

  @JsonKey(name: "offchain_id")
  String offchainOfferId;

}
