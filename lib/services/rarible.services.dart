import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/config/chains.dart';
import 'package:ownerchip_whitelabel/domain/blockchain_token.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/domain/web3MarketplaceApi.dart';
import 'package:ownerchip_whitelabel/services/backend/offer/backendOffer.dart';
import 'package:ownerchip_whitelabel/services/marketplace/types.dart';
import 'package:sentry/sentry.dart';
import 'package:web3dart/web3dart.dart';

Map<String, dynamic> getRaribleAssetType(int chainId, BlockchainToken? token) {
  if (token == null) {
    return {
      "@type": "ETH",
      "blockchain": chainConfig[chainId]!.raribleEnum,
    };
  } else {
    return {
      "@type": "ERC20",
      "contract":
          "${chainConfig[chainId]!.raribleEnum}:${token!.contractAddress.hex}",
    };
  }
}

RaribleV2Order makeRaribleV2Order(
  EthereumAddress payoutAddress,
  EthereumAddress originFeesAddress,
  BigInt tokenId,
  EthereumAddress makerAddress,
  int payoutValue,
  int originFeesValue,
  EthereumAddress voucherContractAddress,
  BigInt voucherTokenId,
  BigInt salePriceInCrypto,
  String? signature,
  int chainId,
  BlockchainToken? blockchainToken,
) {
  final RariblePayout payout = RariblePayout(
    account: payoutAddress,
    value: payoutValue,
    chainId: chainId,
  ); //seller address (controller contract)
  final RariblePayout originFees = RariblePayout(
    account: originFeesAddress,
    value: originFeesValue,
    chainId: chainId,
  );
  final RaribleDataObject dataObject = RaribleDataObject(
      dataType: "ETH_RARIBLE_V2", payouts: [payout], originFees: [originFees]);
  final EthereumAddress maker =
      makerAddress; //seller address (controller contract)
  final make = RaribleOrderFormAsset(
      assetType: RaribleAssetType(
          assetClass: "ERC721",
          contract: voucherContractAddress,
          tokenId: voucherTokenId),
      value: BigInt.from(1));
  final take = RaribleOrderFormAsset(
      assetType:
          RaribleAssetType(assetClass: "ETH", contract: null, tokenId: null),
      value: salePriceInCrypto);
  final BigInt salt = BigInt.from(DateTime.now().millisecondsSinceEpoch);
  final RaribleV2Order raribleV2Order = RaribleV2Order(
    data: dataObject,
    maker: maker,
    make: make,
    takeDeprecated: take,
    take: salePriceInCrypto.toString(),
    takeType: getRaribleAssetType(chainId, blockchainToken),
    salt: salt,
    //now in seconds
    start: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    //end now in 10 months; 2629800 = 1 month in seconds
    end: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 2629800 * 10,
    signature: signature ?? '',
    chainId: chainId,
    blockchainToken: blockchainToken,
  );
  return raribleV2Order;
}

Map<String, dynamic> getRaribleMakeOrderTypeData(int chainId) {
  return {
    'types': {
      'EIP712Domain': EIP712DomainWithChainId,
      'AssetType': AssetType,
      'Asset': Asset,
      'Order': Order,
    },
    'domain': {
      'name': 'Exchange',
      'version': '2',
      'chainId': chainId,
      'verifyingContract': raribleExchangeV2Contracts[chainId],
    },
    'primaryType': 'Order',
  };
}

Future<RaribleHashAndEncodedData> getRaribleOrderTypedDataHash(
    int chainId, RaribleV2Order order) async {
  //call backend to get hash of typed data & encoded data
  return await BackendOffer.getRaribleOfferTypedDataHashAndEncodedData(
    getRaribleMakeOrderTypeData(chainId),
    order,
  );
}

// create rarible order api call
Future<String> prepareRaribleOrderCancellation(
    int chainId, String offchainOrderId) async {
  try {

    if(offchainOrderId.split(":").length < 2) {
      offchainOrderId = "${chainConfig[chainId]!.raribleEnum}:$offchainOrderId";
    }

    final Dio dio = Dio();
    dio.options.headers['X-API-KEY'] = dotenv.get('MAINNET_RARIBLE_API_KEY');
    Response result = await dio.post(
      '${raribleNewApiBaseUrl}orders/$offchainOrderId/prepareCancelTx',
    );
    return result.data["data"];
  } catch (e, s) {
    Sentry.captureException(
      e,
      stackTrace: s,
    );
    print(e);
    return "";
  }
}

//make rarible token page url

String makeRaribleTokenPageUrl(
    int chainId, EthereumAddress collectionId, BigInt tokenId) {
  return '${raribleTokenPageUrls[chainId]!}${collectionId.hex}:$tokenId';
}

// format is: rarible.com/token/polygon/[collectionAddressInHex]:[tokenIdInDecimal]
const raribleTokenPageUrls = {
  1: 'https://rarible.com/token/',
  137: 'https://rarible.com/token/polygon/',
  // 80001: 'https://testnet.rarible.com/token/polygon/',
};
