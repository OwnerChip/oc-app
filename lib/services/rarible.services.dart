import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/domain/web3MarketplaceApi.dart';
import 'package:ownerchip_whitelabel/services/backend.services.dart';
import 'package:ownerchip_whitelabel/services/marketplace/types.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sentry_dio/sentry_dio.dart';
import 'package:sentry/sentry.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';

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
    String? signature) {
  final RariblePayout payout = RariblePayout(
      account: payoutAddress,
      value: payoutValue); //seller address (controller contract)
  final RariblePayout originFees =
      RariblePayout(account: originFeesAddress, value: originFeesValue);
  final RaribleDataObject dataObject = RaribleDataObject(
      dataType: "RARIBLE_V2_DATA_V1",
      payouts: [payout],
      originFees: [originFees]);
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
      take: take,
      salt: salt,
      start: 0,
      //end now in 10 years
      end: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 315360000,
      signature: signature ?? '');
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

Future<String> getRaribleOrderTypedDataHash(
    int chainId, RaribleV2Order order) async {
  //call backend to get hash of typed data
  return await getRaribeOfferTypedDataHash(
      getRaribleMakeOrderTypeData(chainId), order);
}

// create rarible order api call
Future createRaribleOrder(int chainId, RaribleV2Order order) async {
  final String url = raribleUpsertOrderApiUrls[chainId]!;
  try {
    final Dio dio = Dio();
    dio.options.headers['X-API-KEY'] = dotenv.get('MAINNET_RARIBLE_API_KEY');
    Response result = await dio.post(url, data: jsonEncode(order.toJson()));
    print(result);
    return result.data;
  } catch (e, s) {
    Sentry.captureException(
      e,
      stackTrace: s,
    );
    print(e);
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
  80001: 'https://testnet.rarible.com/token/polygon/',
};
