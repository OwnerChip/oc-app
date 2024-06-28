import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/config/chains.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';
import 'package:sentry_dio/sentry_dio.dart';

abstract class Rarible {

  static const Map<int, String> raribleApiUrls = {
    1: 'https://api.rarible.org/v0.1',
    137: 'https://api.rarible.org/v0.1',
    11155111: 'https://testnet-api.rarible.org/v0.1',
    // 80001: 'https://testnet-api.rarible.org/v0.1/order/orders/'
  };

  static Dio getRaribleClient({
    required int chainId,
  }) {
    final chain = chainConfig[chainId]!;
    final Dio dio = Dio(
      BaseOptions(
        baseUrl: raribleApiUrls[chainId]!,
        headers: {
          "X-API-KEY": chain.internal
              ? dotenv.get('TESTNET_RARIBLE_API_KEY')
              : dotenv.get('MAINNET_RARIBLE_API_KEY'),
        },
        validateStatus: (status) {
          return status != null && status < 500;
        },
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(
        TalkerDioLoggerExtension.instance,
      );
    }

    dio.addSentry();

    return dio;
  }
}
