import 'package:json_annotation/json_annotation.dart';
import 'package:ownerchip_whitelabel/domain/activeOffer/activeOffer.dart';

part 'token.g.dart';

@JsonSerializable(explicitToJson: true)
class Token {
  factory Token.fromJson(Map<String, dynamic> json) => _$TokenFromJson(json);

  Map<String, dynamic> toJson() => _$TokenToJson(this);

  Token({
    required this.tokenId,
    required this.mintedAt,
    required this.collectionAddress,
    required this.collectionName,
    required this.collectionSymbol,
    required this.hasVoucherToken,
    required this.voucherCollection,
    required this.voucherTokenUri,
    required this.hasActiveOffer,
    required this.activeOffers,
  });

  String tokenId;
  DateTime mintedAt;
  String collectionAddress;
  String collectionName;
  String collectionSymbol;
  bool hasVoucherToken;
  String voucherCollection;
  String voucherTokenUri;
  bool hasActiveOffer;
  List<ActiveOffer> activeOffers;
}
