import 'dart:convert';

Token tokenFromJson(String str) => Token.fromJson(json.decode(str));

String tokenToJson(Token data) => json.encode(data.toJson());

class Token {
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

  factory Token.fromJson(Map<String, dynamic> json) => Token(
        tokenId: json["tokenId"],
        mintedAt: DateTime.parse(json["mintedAt"]),
        collectionAddress: json["collectionAddress"],
        collectionName: json["collectionName"],
        collectionSymbol: json["collectionSymbol"],
        hasVoucherToken: json["hasVoucherToken"],
        voucherCollection: json["voucherCollection"],
        voucherTokenUri: json["voucherTokenUri"],
        hasActiveOffer: json["hasActiveOffer"],
        activeOffers: List<ActiveOffer>.from(
            json["activeOffers"].map((x) => ActiveOffer.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "tokenId": tokenId,
        "mintedAt": mintedAt.toIso8601String(),
        "collectionAddress": collectionAddress,
        "collectionName": collectionName,
        "collectionSymbol": collectionSymbol,
        "hasVoucherToken": hasVoucherToken,
        "voucherCollection": voucherCollection,
        "voucherTokenUri": voucherTokenUri,
        "hasActiveOffer": hasActiveOffer,
        "activeOffers": List<dynamic>.from(activeOffers.map((x) => x.toJson())),
      };
}

class ActiveOffer {
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
  });

  String offerHash;
  String offerPrice;
  String offerCurrency;
  String sellerEmail;
  String sellerAddress;
  String sellerPayoutAddress;
  DateTime createdAt;
  int validUntil;
  String encodedData;
  String marketplaceContract;
  bool isCancelled;

  factory ActiveOffer.fromJson(Map<String, dynamic> json) => ActiveOffer(
        offerHash: json["offer_hash"],
        offerPrice: json["offer_price"],
        offerCurrency: json["offer_currency"],
        sellerEmail: json["seller_email"],
        sellerAddress: json["seller_address"],
        sellerPayoutAddress: json["seller_payout_address"],
        createdAt: DateTime.parse(json["created_at"]),
        validUntil: json["valid_until"],
        encodedData: json["encoded_data"],
        marketplaceContract: json["marketplace_contract"],
        isCancelled: json["is_cancelled"],
      );

  Map<String, dynamic> toJson() => {
        "offer_hash": offerHash,
        "offer_price": offerPrice,
        "offer_currency": offerCurrency,
        "seller_email": sellerEmail,
        "seller_address": sellerAddress,
        "seller_payout_address": sellerPayoutAddress,
        "created_at": createdAt.toIso8601String(),
        "valid_until": validUntil,
        "encoded_data": encodedData,
        "marketplace_contract": marketplaceContract,
        "is_cancelled": isCancelled,
      };
}
