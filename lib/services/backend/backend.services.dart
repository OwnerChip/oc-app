import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/services/backend/app/backendAppService.dart';
import 'package:ownerchip_whitelabel/services/backend/attachments/backendAttachments.dart';
import 'package:ownerchip_whitelabel/services/backend/attachments/backendAttachmentsService.dart';
import 'package:ownerchip_whitelabel/services/backend/auth/backendAuthService.dart';
import 'package:ownerchip_whitelabel/services/backend/collection/backendCollectionService.dart';
import 'package:ownerchip_whitelabel/services/backend/creation/backendCreationService.dart';
import 'package:ownerchip_whitelabel/services/backend/creator/backendCreatorService.dart';
import 'package:ownerchip_whitelabel/services/backend/customer/backendCustomerService.dart';
import 'package:ownerchip_whitelabel/services/backend/fcm/backendFcmService.dart';
import 'package:ownerchip_whitelabel/services/backend/metaTx/backendMetaTxService.dart';
import 'package:ownerchip_whitelabel/services/backend/offer/backendOfferService.dart';
import 'package:ownerchip_whitelabel/services/backend/token/backendTokenService.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';
import 'package:sentry/sentry.dart';
import 'package:sentry_dio/sentry_dio.dart';

abstract class Backend {
  /// get OC backend client (with sentry interceptor)
  static getBackendClient({
    String? jwt,
    bool forceProduction = false,
  }) {
    final client = Dio(
      BaseOptions(
        // baseUrl: dotenv.get('IS_INTERNAL') == 'true' && !forceProduction
        //     ? dotenv.get('OC_BACKEND_URL_TEST')
        //     : dotenv.get('OC_BACKEND_URL'),
        baseUrl: 'http://192.168.31.214:3000',
        headers: {
          "app_id": dotenv.get('BITRISEIO_PACKAGE_NAME'),
          "lang": "en",
          "Authorization": jwt != null ? "Bearer $jwt" : "",
        },
        validateStatus: (status) {
          return status != null && status < 500;
        },
      ),
    );

    if (kDebugMode) {
      client.interceptors.add(
        TalkerDioLoggerExtension.instance,
      );
    }

    client.addSentry();

    return client;
  }

  static void recreateServices(String? jwt) {
    if (jwt != null && jwt.isEmpty) {
      jwt = null;
    }
    if(jwt == null) {
      talker.debug("JWT is null", StackTrace.current);
    }

    talker.info('Recreating backend services with new JWT.\n$jwt');

    BackendAuthService.recreate(jwt);
    BackendMetaTxService.recreate(jwt);
    BackendOfferService.recreate(jwt);
    BackendAppService.recreate(jwt);
    BackendTokenService.recreate(jwt);
    BackendCollectionService.recreate(jwt);
    BackendCustomerService.recreate(jwt);
    BackendCreatorService.recreate(jwt);
    BackendAttachmentsService.recreate(jwt);
    BackendFcmService.recreate(jwt);
    BackendCreationService.recreate(jwt);
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