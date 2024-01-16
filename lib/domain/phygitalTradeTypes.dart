import 'package:web3dart/web3dart.dart';

class Purchase {
  String purchaseTxHash;
  DateTime createdAt;
  bool isRedeemed;
  DateTime? redeemedAt;
  Buyer buyer;
  PurchaseTokenData token;
  Offer offer;
  ShippingInfo? shippingInfo;

  Purchase({
    required this.purchaseTxHash,
    required this.createdAt,
    required this.isRedeemed,
    this.redeemedAt,
    required this.buyer,
    required this.token,
    required this.offer,
    this.shippingInfo,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) => Purchase(
        purchaseTxHash: json["purchase_tx_hash"],
        createdAt: DateTime.parse(json["created_at"]),
        isRedeemed: json["is_redeemed"],
        redeemedAt: json["redeemed_at"] == null
            ? null
            : DateTime.parse(json["redeemed_at"]),
        buyer: Buyer.fromJson(json["buyer"]),
        token: PurchaseTokenData.fromJson(json["token"]),
        offer: Offer.fromJson(json["offer"]),
        shippingInfo: json["shipping_info"] == null
            ? null
            : ShippingInfo.fromJson(json["shipping_info"]),
      );
}

class Buyer {
  EthereumAddress walletAddress;
  String firstName;
  String lastName;
  String email;
  String phoneNumber;
  DateTime createdAt;
  String companyName;

  Buyer({
    required this.walletAddress,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.createdAt,
    required this.companyName,
  });

  factory Buyer.fromJson(Map<String, dynamic> json) => Buyer(
        walletAddress: EthereumAddress.fromHex(json["id"]),
        firstName: json["first_name"],
        lastName: json["last_name"],
        email: json["email"],
        phoneNumber: json["phone_number"],
        createdAt: DateTime.parse(json["created_at"]),
        companyName: json["company_name"],
      );
}

class PurchaseTokenData {
  BigInt id;
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

  factory PurchaseTokenData.fromJson(Map<String, dynamic> json) =>
      PurchaseTokenData(
        id: BigInt.parse(json["id"]),
        createdAt: DateTime.parse(json["created_at"]),
        recoverySignature: json["recovery_signature"],
        voucherTokenUri: json["voucher_token_uri"],
        hasVoucherToken: json["has_voucher_token"],
      );
}

class Offer {
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
  bool isFilled;

  Offer({
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
    required this.isFilled,
  });

  factory Offer.fromJson(Map<String, dynamic> json) => Offer(
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
        isFilled: json["is_filled"],
      );
}

class ShippingInfo {
  String firstName;
  String lastName;
  String email;
  String phoneNumber;
  String companyName;
  String streetAddress;
  String streetAddress1;
  String city;
  String postalCode;
  String stateOrProvince;
  String countryCode;

  ShippingInfo({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.companyName,
    required this.streetAddress,
    required this.streetAddress1,
    required this.city,
    required this.postalCode,
    required this.stateOrProvince,
    required this.countryCode,
  });

  factory ShippingInfo.fromJson(Map<String, dynamic> json) {
    return ShippingInfo(
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      email: json['email'] as String,
      phoneNumber: json['phone_number'] as String,
      companyName: json['company_name'] as String,
      streetAddress: json['street_address'] as String,
      streetAddress1: json['street_address1'] as String,
      city: json['city'] as String,
      postalCode: json['postal_code'] as String,
      stateOrProvince: json['state_or_province'] as String,
      countryCode: json['country_code'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone_number': phoneNumber,
      'company_name': companyName,
      'street_address': streetAddress,
      'street_address1': streetAddress1,
      'city': city,
      'postal_code': postalCode,
      'state_or_province': stateOrProvince,
      'country_code': countryCode,
    };
  }
}
