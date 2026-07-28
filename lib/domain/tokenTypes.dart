import 'dart:convert';

Token tokenFromJson(String str) => Token.fromJson(json.decode(str));

String tokenToJson(Token data) => json.encode(data.toJson());

class AlchemyNftTokenIdCollectionChainId {
  AlchemyNftTokenIdCollectionChainId({
    required this.nftTokenId,
    required this.collectionAddress,
    required this.chainId,
    required this.minterAddress,
  });

  String nftTokenId;
  String collectionAddress;
  int chainId;
  String minterAddress;
}

class Token {
  Token({
    required this.tokenId,
    required this.mintedAt,
    required this.collectionAddress,
    required this.collectionName,
    required this.collectionSymbol,
    required this.hasVoucherToken,
    required this.voucherCollection,
    this.voucherTokenUri,
  });

  String tokenId;
  DateTime mintedAt;
  String collectionAddress;
  String collectionName;
  String collectionSymbol;
  bool hasVoucherToken;
  String voucherCollection;
  String? voucherTokenUri;

  factory Token.fromJson(Map<String, dynamic> json) => Token(
        tokenId: json["tokenId"],
        mintedAt: DateTime.parse(json["mintedAt"]),
        collectionAddress: json["collectionAddress"],
        collectionName: json["collectionName"],
        collectionSymbol: json["collectionSymbol"],
        hasVoucherToken: json["hasVoucherToken"],
        voucherCollection: json["voucherCollection"],
        voucherTokenUri: json["voucherTokenUri"],
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
      };
}
