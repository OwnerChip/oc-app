import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/domain/phygitalTradeTypes.dart';
import 'package:ownerchip_whitelabel/domain/tokenTypes.dart';
import 'package:ownerchip_whitelabel/services/backend/analytics/backendAnalytics.dart';
import 'package:ownerchip_whitelabel/services/backend/analytics/backendAnalyticsService.dart';
import 'package:ownerchip_whitelabel/services/backend/auth/backendAuthService.dart';
import 'package:ownerchip_whitelabel/services/backend/metaTx/backendMetaTxService.dart';
import 'package:ownerchip_whitelabel/services/backend/offer/backendOfferService.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:sentry/sentry.dart';
import 'package:sentry_dio/sentry_dio.dart';
import 'package:web3dart/web3dart.dart';

abstract class Backend {
  /// get OC backend client (with sentry interceptor)
  static getBackendClient({
    String? jwt,
  }) {
    final client = Dio(
      BaseOptions(
        baseUrl: dotenv.get('IS_INTERNAL') == 'true'
            ? dotenv.get('OC_BACKEND_URL_TEST')
            : dotenv.get('OC_BACKEND_URL'),
        headers: {
          "app_id": dotenv.get('BITRISEIO_PACKAGE_NAME'),
          "lang": "en",
          "Authorization": jwt != null ? "Bearer $jwt" : "",
        },
      ),
    );

    // client.interceptors.add(
    //   TalkerDioLoggerExtension.instance,
    // );

    client.addSentry();

    return client;
  }

  static void recreateServices(String? jwt) {
    talker.info('Recreating backend services with new JWT.\n$jwt');
    BackendAuthService.recreate(jwt);
    BackendMetaTxService.recreate(jwt);
    BackendOfferService.recreate(jwt);
    BackendAnalyticsService.recreate(jwt);
  }
}

Future<void> sendCardInitToBackend(
    String customerId, EthereumAddress chipAddress) async {
  // send to prod API so that the owner card data is available in the prod DB
  final client = Dio(BaseOptions(
      baseUrl: dotenv.get('OC_BACKEND_URL'),
      headers: {"app_id": dotenv.get('BITRISEIO_PACKAGE_NAME'), "lang": "en"}));
  client.addSentry();
  final String url = '/customer/$customerId/ownercard';
  try {
    final _ = await client.post(url, data: {
      'id': chipAddress.hex,
    });
  } catch (e, s) {
    Sentry.captureException(
      e,
      stackTrace: s,
    );
    print(e);
  }
}

// get a list of all collections associated with a specific app
Future<Map> getAppCollections() async {
  final Dio dio = Backend.getBackendClient();
  final appId = dotenv.get('BITRISEIO_PACKAGE_NAME');
  final String url = '/app/$appId';

  final response = await dio.get(url);
  return response.data;
}

// gets the hash that needs to be used to sign a gasless tx request.
Future<String> getEthSignTypedDataSignature(
    EthereumAddress collectionId, Map<String, dynamic> txRequest) async {
  final Dio dio = Backend.getBackendClient();
  final String url = '/collection/$collectionId/metatx/hash';
  //make post request with dio
  final response = await dio.post(url, data: txRequest);
  return response.data; //hash
}


Future<bool> sendCardLostToBackend(
    EthereumAddress chipAddress,
    EthereumAddress collectionAddress,
    SignatureData chipSignature,
    String sessionId,
    String email,
    String name,
    String telNr) async {
  final Dio dio = Backend.getBackendClient();
  final String url = '/collection/${collectionAddress.hex}/recovery';
  try {
    await dio.post(url, data: {
      'name': name,
      'email': email,
      'telNr': telNr,
      'sessionId': sessionId,
      'chipAddress': chipAddress.hex,
      'chipSignature': {
        'r': convertSignatureParamToHexString(chipSignature.signature.r),
        's': convertSignatureParamToHexString(chipSignature.signature.s),
        'v': chipSignature.signature.v,
      }
    });
    return true;
  } catch (e, s) {
    Sentry.captureException(
      e,
      stackTrace: s,
    );
    print(e);
    return false;
  }
}

//get creator info
Future<CreatorData> getCreatorData(EthereumAddress tokenId) async {
  final Dio dio = Backend.getBackendClient();
  try {
    final Response response = await dio.get('/creator/${tokenId.hex}');
    final Map creatorData = response.data;

    bool hasActiveOffer = creatorData["token"]["hasActiveOffer"];

    return CreatorData(
      name: creatorData['name'],
      affiliation: creatorData['affiliation'],
      email: creatorData['email'],
      walletAddress: EthereumAddress.fromHex(creatorData['address']),
      createdAt: DateTime.parse(creatorData['token']['mintedAt']),
      hasActiveOffer: hasActiveOffer,
      tokenForWhichCreatorDataWasRequested:
          Token.fromJson(creatorData['token']),
    );
  } catch (e) {
    Sentry.captureException(e);
    print(e);
    rethrow;
  }
}

//GET request to https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=USD,EUR,CNY,JPY,GBP

Future<Map> getEthPrice(String cryptoSymbol) async {
  final Dio dio = Dio(BaseOptions(
      baseUrl: 'https://min-api.cryptocompare.com/data',
      headers: {"lang": "en"}));
  String url = '/price?fsym=$cryptoSymbol&tsyms=USD,EUR,CNY,JPY,GBP';
  try {
    final Response response = await dio.get(url);
    return response.data;
  } catch (e) {
    Sentry.captureException(e);
    print(e);
    rethrow;
  }
}






//get unredeemed purchases for tokenId
Future<List<Purchase>> getUnredeemedPurchases(BigInt tokenId) async {
  final Dio dio = Backend.getBackendClient();
  try {
    final String tokenIdHex = convertTokenIdToEthereumAddress(tokenId);
    final Response response =
        await dio.get('/token/$tokenIdHex/purchase/unredeemed');
    final List<dynamic> purchases = response.data;
    return purchases.map((e) => Purchase.fromJson(e)).toList();
  } catch (e) {
    Sentry.captureException(e);
    print(e);
    rethrow;
  }
}

Future<void> postShippingInfoToBackend(
    Purchase purchase, ShippingInfo shippingInfo) async {
  final Dio dio = Backend.getBackendClient();
  final String url =
      '/token/${convertTokenIdToEthereumAddress(purchase.token.id)}/purchase/${purchase.purchaseTxHash}/shippingInfo';
  try {
    await dio.post(url, data: shippingInfo.toJson());
  } catch (e) {
    Sentry.captureException(e);
    print(e);
    rethrow;
  }
}

// POST /token/:tokenId/purchase/:purchaseId/manualHandover with empty body

Future<void> postManualHandoverToBackend(Purchase purchase) async {
  final Dio dio = Backend.getBackendClient();
  final String url =
      '/token/${convertTokenIdToEthereumAddress(purchase.token.id)}/purchase/${purchase.purchaseTxHash}/manualHandover';
  try {
    await dio.post(url);
  } catch (e) {
    Sentry.captureException(e);
    print(e);
    rethrow;
  }
}
