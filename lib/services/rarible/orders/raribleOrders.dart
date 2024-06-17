import 'dart:convert';

import 'package:ownerchip_whitelabel/domain/rarible/raribleV2Order/raribleV2Order.dart';
import 'package:ownerchip_whitelabel/services/rarible/orders/raribleOrdersService.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

abstract class RaribleOrders {
  // create rarible order api call
  static Future<Map> createRaribleOrder({
    required int chainId,
    required RaribleV2Order order,
  }) async {
    try {
      final service = RaribleOrdersService.instance(chainId);
      final result = await service.createOrder(
        payload: order,
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
