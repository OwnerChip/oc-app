import 'dart:convert';

import 'package:ownerchip_whitelabel/domain/web3MarketplaceApi.dart';
import 'package:ownerchip_whitelabel/services/backend/rarible/backendRaribleService.dart';
import 'package:ownerchip_whitelabel/services/backend/rarible/payloads/makeRaribleRequestPayload.dart';
import 'package:ownerchip_whitelabel/services/backend/rarible/payloads/raribleRequestConfig.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

abstract class RaribleOrders {
  static Future<Map> encodeDataForSign({
    required int chainId,
    required RaribleV2Order order,
  }) async {
    try {
      final result = await BackendRaribleService.instance.makeRaribleRequest(
        MakeRaribleRequestPayload(
          config: RaribleRequestConfig(
            method: "POST",
            endpoint: "/encode/order",
            body: order.toJson(),
            headers: {},
          ),
          chainId: chainId,
        ),
      );

      talker.debug(result.data);

      if (result.data is String) {
        return jsonDecode(result.data);
      }

      return result.data;
    } catch (e, s) {
      Sentry.captureException(
        e,
        stackTrace: s,
      );
      talker.error(e, s);
      rethrow;
    }
  }

  // create rarible order api call
  static Future<Map> createRaribleOrder({
    required int chainId,
    required RaribleV2Order order,
  }) async {
    try {
      final result = await BackendRaribleService.instance.makeRaribleRequest(
        MakeRaribleRequestPayload(
          config: RaribleRequestConfig(
            method: "POST",
            endpoint: "/orders/",
            body: order.toJson(),
            headers: {},
          ),
          chainId: chainId,
        ),
      );

      final map = order.toJson();
      final json = jsonEncode(map);

      talker.info(result.data);

      return result.data;
    } catch (e, s) {
      Sentry.captureException(
        e,
        stackTrace: s,
      );
      talker.error(e, s);
      rethrow;
    }
  }
}
