import 'package:web3dart/web3dart.dart';

/** RARIBLE */

final Map<int, String> raribleUpsertOrderApiUrls = {
  1: 'https://ethereum-api.rarible.org/v0.1/order/orders/',
  137: 'https://polygon-api.rarible.org/v0.1/order/orders/',
  80001: 'https://testnet-api.rarible.org/v0.1/order/orders/'
};

const String raribleNewApiBaseUrl = 'https://api.rarible.org/v0.1/';

final Map<int, String> raribleExchangeV2Contracts = {
  1: '0x9757F2d2b135150BBeb65308D4a91804107cd8D6',
  137: '0x12b3897a36fDB436ddE2788C06Eff0ffD997066e',
  //42161: '0x07b637739CAd9A5f0c487219B283a52717E69978', arbitrum (maybe later)
  80001: '0x2Fc743F5419637B93dDAC159715B902186300041'
};

final Map<int, String> raribleTransferProxies = {
  1: '0x4fee7b061c97c9c496b01dbce9cdb10c02f0a0be',
  137: '0xd47e14DD9b98411754f722B4c4074e14752Ada7C',
  //42161: '0x49b4e47079d9b733B2227fa15f0762dBF707B263', arbitrum (maybe later)
  80001: '0x02e21199D043dab90248f79d6A8d0c36832734B0'
};

class RaribleV2Order {
  final String type = "RARIBLE_V2";
  final RaribleDataObject data;
  final EthereumAddress maker;
  final RaribleOrderFormAsset make;
  final RaribleOrderFormAsset take;
  final BigInt salt;
  final int start;
  final int end;
  final String signature;

  RaribleV2Order(
      {required this.data,
      required this.maker,
      required this.make,
      required this.take,
      required this.salt,
      required this.start,
      required this.end,
      required this.signature});

  RaribleV2Order setSignature(String signature) {
    return RaribleV2Order(
        data: data,
        maker: maker,
        make: make,
        take: take,
        salt: salt,
        start: start,
        end: end,
        signature: signature);
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'data': {
        'dataType': data.dataType,
        'payouts': data.payouts.map((e) => e.toJson()).toList(),
        'originFees': data.originFees.map((e) => e.toJson()).toList(),
      },
      'maker': maker.hex,
      'make': {
        'assetType': {
          'assetClass': make.assetType.assetClass,
          'contract': make.assetType.contract?.hex,
          'tokenId': make.assetType.tokenId.toString(),
        },
        'value': make.value.toString(),
      },
      'take': {
        'assetType': {
          'assetClass': take.assetType.assetClass,
          'contract': take.assetType.contract?.hex,
          'tokenId': take.assetType.tokenId.toString(),
        },
        'value': take.value.toString(),
      },
      'salt': salt.toString(),
      'start': start,
      'end': end,
      'signature': signature,
    };
  }
}

class RaribleDataObject {
  final String dataType;
  final List<RariblePayout> payouts;
  final List<RariblePayout> originFees;

  RaribleDataObject(
      {required this.dataType,
      required this.payouts,
      required this.originFees});

  Map<String, dynamic> toJson() {
    return {
      'dataType': dataType,
      'payouts': payouts.map((e) => e.toJson()).toList(),
      'originFees': originFees.map((e) => e.toJson()).toList(),
    };
  }
}

class RaribleOrderFormAsset {
  final RaribleAssetType assetType;
  final BigInt value;

  RaribleOrderFormAsset({required this.assetType, required this.value});

  Map<String, dynamic> toJson() {
    return {
      'assetType': {
        'assetClass': assetType.assetClass,
        'contract': assetType.contract?.hex,
        'tokenId': assetType.tokenId.toString(),
      },
      'value': value.toString(),
    };
  }
}

class RaribleAssetType {
  final String assetClass;
  final EthereumAddress? contract;
  final BigInt? tokenId;

  RaribleAssetType({required this.assetClass, this.contract, this.tokenId});

  Map<String, dynamic> toJson() {
    return {
      'assetClass': assetClass,
      'contract': contract?.hex,
      'tokenId': tokenId.toString(),
    };
  }
}

class RariblePayout {
  final EthereumAddress account;
  final int value; // in bps (100=1%)

  RariblePayout({required this.account, required this.value});

  Map<String, dynamic> toJson() {
    return {
      'account': account.hex,
      'value': value,
    };
  }
}

/** OPENSEA */

final Map<int, String> openSeaV2ListingRequestApiUrls = {
  1: 'https://api.opensea.io/api/v2/orders/ethereum/seaport/listings',
  137: 'https://api.opensea.io/api/v2/orders/polygon/seaport/listings'
};

class OpenSeaV2ListingRequest {
  final OpenSeaListingParams listingParams; // Represents listing parameters.
  final String
      signature; // Signed type data represented by the parameters field.
  final String protocolAddress = "0x00000000000000adc04c56bf30ac9d3c0aaf14dc";

  OpenSeaV2ListingRequest({
    required this.listingParams,
    required this.signature,
  });
}

class OpenSeaListingParams {
  final String
      offerer; // The address which supplies all the items in the offer.
  final List<OpenSeaOffer>
      offer; // Items that may be transferred from the offerer's account.
  final List<OpenSeaConsideration>
      consideration; // Array of items which must be received by a recipient to fulfill the order. One of the consideration items must be the OpenSea marketplace fee.
  final int startTime; // blockTime
  final int endTime; // blockTime
  final String orderType; // e.g. "listing"
  final String salt; // arbitrary source of entropy
  final String zone = '0x0000000000000000000000000000000000000000';
  final String zoneHash =
      '0x0000000000000000000000000000000000000000000000000000000000000000';
  final String conduitKey =
      "0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000";
  final int
      counter; // Must match the current counter for the given offerer. https://etherscan.io/address/0x00000000000000adc04c56bf30ac9d3c0aaf14dc#readContract#F2

  OpenSeaListingParams({
    required this.offerer,
    required this.offer,
    required this.consideration,
    required this.startTime,
    required this.endTime,
    required this.orderType,
    required this.salt,
    required this.counter,
  });
}

class OpenSeaOffer {
  final int itemType;
  final String token; // Contract address
  final int identifierOrCriteria;
  final int startAmount;
  final int endAmount; // usually the start amount

  OpenSeaOffer({
    required this.itemType,
    required this.token,
    required this.identifierOrCriteria,
    required this.startAmount,
    required this.endAmount,
  });
}

class OpenSeaConsideration extends OpenSeaOffer {
  final String
      recipient; // The address which will receive the consideration item when the order is executed.

  OpenSeaConsideration({
    required this.recipient,
    required int itemType,
    required String token,
    required int identifierOrCriteria,
    required int startAmount,
    required int endAmount,
  }) : super(
          itemType: itemType,
          token: token,
          identifierOrCriteria: identifierOrCriteria,
          startAmount: startAmount,
          endAmount: endAmount,
        );
}
