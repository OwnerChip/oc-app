import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/config/wallets.dart';
import 'package:ownerchip_whitelabel/domain/creatorData/creatorData.dart';
import 'package:ownerchip_whitelabel/domain/offerItemInputData/offerItemInputData.dart';
import 'package:ownerchip_whitelabel/domain/phygital/purchase/purchase.dart';
import 'package:ownerchip_whitelabel/domain/phygital/shippingInfo/shippingInfo.dart';
import 'package:ownerchip_whitelabel/domain/rarible/raribleV2Order/raribleV2Order.dart';
import 'package:ownerchip_whitelabel/domain/rartibleHashAndEncodedData/raribleHashAndEncededData.dart';
import 'package:ownerchip_whitelabel/domain/signatureData/signatureData.dart';
import 'package:ownerchip_whitelabel/domain/token/token.dart';
import 'package:ownerchip_whitelabel/domain/userSession/userSession.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:sentry/sentry.dart';
import 'package:sentry_dio/sentry_dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

/// get OC backend client (with sentry interceptor)
Dio getBackendClient() {
  final client = Dio(BaseOptions(
      baseUrl: dotenv.get('IS_INTERNAL') == 'true'
          ? dotenv.get('OC_BACKEND_URL_TEST')
          : dotenv.get('OC_BACKEND_URL'),
      headers: {"app_id": dotenv.get('BITRISEIO_PACKAGE_NAME'), "lang": "en"}));
  client.addSentry();
  return client;
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
  final Dio dio = getBackendClient();
  final appId = dotenv.get('BITRISEIO_PACKAGE_NAME');
  final String url = '/app/$appId';

  final response = await dio.get(url);
  return response.data;
}

// Checks if a gasless transaction is supported by a collection.
// Returns a tuple of [bool, String].
// bool: true if a meta transaction is supported, false otherwise.
// String: the id of the meta transaction agreement if it is supported.
//         the error message if it is not supported.
Future<List<dynamic>> checkMetaTx(
    EthereumAddress collectionId, String functionSignatureHash) async {
  final Dio dio = getBackendClient();
  final String url = '/collection/$collectionId/metaTx/$functionSignatureHash';
  try {
    final response = await dio.get(url);
    final String metaTxAgreementId = response.data;
    return [true, metaTxAgreementId];
  } catch (e) {
    return [false, e];
  }
}

// This function will send a gasless request to the backend. The backend will then
// send a meta transaction to the network.
Future<String> sendGaslessRequest(
    EthereumAddress collectionId,
    String txSignature,
    String metaTxAgreementId,
    Map<String, dynamic> txRequest) async {
  final Dio dio = getBackendClient();
  final String url = '/collection/$collectionId/metatx';
  //make post request with dio
  final response = await dio.post(url, data: {
    "txSignature": txSignature,
    "metaTxAgreementId": metaTxAgreementId,
    "txRequest": txRequest
  });
  return response.data; //txId
}

// gets the hash that needs to be used to sign a gasless tx request.
Future<String> getEthSignTypedDataSignature(
    EthereumAddress collectionId, Map<String, dynamic> txRequest) async {
  final Dio dio = getBackendClient();
  final String url = '/collection/$collectionId/metatx/hash';
  //make post request with dio
  final response = await dio.post(url, data: txRequest);
  return response.data; //hash
}

// This function will post a user action to the analytics backend.
Future<void> sendAnalyticsTrace(String caseId, String description, String type,
    {Map<String, dynamic>? tags}) async {
  final Dio dio = getBackendClient();
  final String url = '/app/${dotenv.get('BITRISEIO_PACKAGE_NAME')}/action';
  //make post request with dio (do not care about response)
  try {
    await dio.post(url, data: {
      "case_id": caseId,
      "description": description,
      "type": type,
      "tags": jsonEncode(tags)
    });
  } catch (e, s) {
    await Sentry.captureException(
      e,
      stackTrace: s,
    );
    print(e);
  }
}

// This function requests a Session Id from the backend
Future<String> getSessionId() async {
  final Dio dio = getBackendClient();
  try {
    final response = await dio.get('/auth');
    final String sessionId = response.data;
    return sessionId;
  } catch (e, s) {
    await Sentry.captureException(
      e,
      stackTrace: s,
    );
    print(e);
    //fallback!
    return makeRandomInt().toString();
  }
}

Future<dynamic> getSessionExpiration(int sessionDuration, String sessionId,
    EthereumAddress userWalletAddress, MsgSignature signature) async {
  final Dio dio = getBackendClient();
  try {
    final response = await dio.post('/auth/${sessionDuration}',
        data: {
          "sessionId": sessionId,
          "walletAddress": userWalletAddress.hex,
          "userWalletSignature": {
            'r': convertSignatureParamToHexString(signature.r),
            's': convertSignatureParamToHexString(signature.s),
            'v': signature.v
          }
        },
        options: Options(
          responseType: ResponseType.plain,
        ));
    return int.parse(response.data); // unix expiration timestamp
  } catch (e, s) {
    await Sentry.captureException(
      e,
      stackTrace: s,
    );
    print(e);
    return 0;
  }
}

/// save a userSession of a OwnerCard
Future<void> saveUserSession(
    String sessionId,
    EthereumAddress cardWalletAddress,
    MsgSignature signature,
    WidgetRef ref) async {
  int sevenDaysInSeconds = 60 * 60 * 24 * 7;
  int sessionExpirationDate = await getSessionExpiration(
      sevenDaysInSeconds, sessionId, cardWalletAddress, signature);

  ref.read(userAddressProvider.notifier).state = cardWalletAddress;
  ref.read(walletTypeProvider.notifier).state = walletConfig['ownerCard'];
  const isOwnerCard = true;
  UserSession userSession = UserSession(sessionId, signature,
      ref.read(userAddressProvider), isOwnerCard, sessionExpirationDate);

  ref.read(userSessionProvider.notifier).state = userSession;

  //persist session date
  final SharedPreferences storage = await SharedPreferences.getInstance();
  final String jsonUserSession = jsonEncode(userSession.toJson());
  storage.setString('userSession', jsonUserSession);
}

Future<bool> sendCardLostToBackend(
    EthereumAddress chipAddress,
    EthereumAddress collectionAddress,
    SignatureData chipSignature,
    String sessionId,
    String email,
    String name,
    String telNr) async {
  final Dio dio = getBackendClient();
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
  final Dio dio = getBackendClient();
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

Future<void> sendOfferItemInfoToBackend(OfferItemInputData dto) async {
  final Dio dio = getBackendClient();
  final String url = '/offer';
  try {
    await dio.post(url, data: dto.toJson());
  } catch (e) {
    Sentry.captureException(e);
    print(e);
    rethrow;
  }
}

Future<void> cancelOfferBackendRequest(String offerHash) async {
  final Dio dio = getBackendClient();
  final String url = '/offer/cancel/$offerHash';
  try {
    await dio.post(url);
  } catch (e) {
    Sentry.captureException(e);
    print(e);
    rethrow;
  }
}

// backend encodes message and returns hash of typed data
Future<RaribleHashAndEncodedData> getRaribleOfferTypedDataHashAndEncodedData(
    Map typedData, RaribleV2Order order) async {
  try {
    final Dio dio = getBackendClient();
    final result = await dio.post('/offer/hash/rarible',
        data: jsonEncode({'typedData': typedData, 'message': order.toJson()}));
    print(result.data);
    return RaribleHashAndEncodedData(
        result.data['typedDataHash'], result.data['encodedData']);
  } catch (e, s) {
    Sentry.captureException(
      e,
      stackTrace: s,
    );
    print(e);
    rethrow;
  }
}

//get unredeemed purchases for tokenId
Future<List<Purchase>> getUnredeemedPurchases(BigInt tokenId) async {
  final Dio dio = getBackendClient();
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
  final Dio dio = getBackendClient();
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
  final Dio dio = getBackendClient();
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
