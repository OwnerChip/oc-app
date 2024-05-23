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

  String offerHash;
  String offerPrice;
  String offerCurrency;
  String sellerEmail;
  String sellerAddress;
  String sellerPayoutAddress;

  @DateIso8601JsonConverter()
  DateTime createdAt;
  int validUntil;
  String encodedData;
  String marketplaceContract;
  bool isCancelled;
  String offchainOfferId;

}
