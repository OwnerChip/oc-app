
import 'package:ownerchip_whitelabel/domain/phygitalTradeTypes.dart';
import 'package:ownerchip_whitelabel/services/backend/backend.services.dart';
import 'package:ownerchip_whitelabel/services/backend/token/backendTokenService.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

abstract class BackendToken extends Backend {
  //get unredeemed purchases for tokenId
  static Future<List<Purchase>> getUnredeemedPurchases(BigInt tokenId) async {
    final service = BackendTokenService.instance;
    try {
      final String tokenIdHex = convertTokenIdToEthereumAddress(tokenId);
      final response =
          await service.getUnredeemedPurchases(tokenIdHex).catchError((e) {
        throw e;
      });
      final List<Purchase> purchases = [];

      for (final purchase in response.data) {
        purchases.add(
          Purchase.fromJson(purchase as Map<String, dynamic>),
        );
      }

      return purchases;
    } catch (e, st) {
      Sentry.captureException(e);
      talker.error(e, st);
      rethrow;
    }
  }

  static Future<void> postShippingInfoToBackend(
      Purchase purchase, ShippingInfo shippingInfo) async {
    final service = BackendTokenService.instance;
    try {
      await service
          .postShippingInfoToBackend(
        convertTokenIdToEthereumAddress(purchase.token.id),
        purchase.purchaseTxHash,
        shippingInfo,
      )
          .catchError((e) {
        throw e;
      });
    } catch (e, st) {
      Sentry.captureException(e);
      talker.error(e, st);
      rethrow;
    }
  }

  // POST /token/:tokenId/purchase/:purchaseId/manualHandover with empty body
  static Future<void> postManualHandoverToBackend(Purchase purchase) async {
    final service = BackendTokenService.instance;
    final String url =
        '/token/${convertTokenIdToEthereumAddress(purchase.token.id)}/purchase/${purchase.purchaseTxHash}/manualHandover';
    try {
      await service
          .postManualHandoverToBackend(
        convertTokenIdToEthereumAddress(purchase.token.id),
        purchase.purchaseTxHash,
      )
          .catchError((e) {
        throw e;
      });
    } catch (e, st) {
      Sentry.captureException(e);
      talker.error(e, st);
      rethrow;
    }
  }
}
