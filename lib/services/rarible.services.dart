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
    BigInt salePriceInCrypto) {
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
      end: 1711688790,
      signature: "");
  return raribleV2Order;
}

// create rarible order api call
Future<void> createRaribleOrder(int chainId, RaribleV2Order order) async {
  final String url = raribleUpsertOrderApiUrls[chainId]!;
  try {
    final Dio dio = Dio();
    dio.options.headers['X-API-KEY'] = dotenv.get('MAINNET_RARIBLE_API_KEY');
    await dio.post(url, data: jsonEncode(order.toJson()));
  } catch (e, s) {
    Sentry.captureException(
      e,
      stackTrace: s,
    );
    print(e);
  }
}

// backend encodes message and returns hash of typed data
Future getTypedDataHash(Map typedData, RaribleV2Order order) async {
  try {
    final Dio dio = getBackendClient();
    String url = '/getHash'; //TODO: send do correct endpoint
    final typedDataHash = await dio.post(url,
        data: jsonEncode({'typedData': typedData, 'message': order.toJson()}));
    return typedDataHash;
  } catch (e, s) {
    Sentry.captureException(
      e,
      stackTrace: s,
    );
    print(e);
  }
}

Map<String, dynamic> getRaribleMakeOrderTypeData(int chainId) {
  final String verifyingContract =
      '0x08268aD94BfE1909878Ac702Be6170c645745A92'; //TODO: dont hardcode controller contract
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
      'chainId': chainId.toString(),
      'verifyingContract': verifyingContract,
    },
    'primaryType': 'Order',
  };
}

Future<Map<String, dynamic>> getRaribleMakeOrderTypedDataHash(
    int chainId, RaribleV2Order order) async {
  //TODO: call backend sending typed data and message
  final Map<String, dynamic> typeData = getRaribleMakeOrderTypeData(chainId);
  final result = await getTypedDataHash(typeData, order);
  return result;
}
