import 'dart:convert';

import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/domain/web3MarketplaceApi.dart';
import 'package:ownerchip_whitelabel/services/backend/backend.services.dart';
import 'package:ownerchip_whitelabel/services/backend/offer/backendOfferService.dart';
import 'package:ownerchip_whitelabel/services/backend/offer/payloads/offerItemPayload.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

abstract class BackendOffer extends Backend {
  static Future<void> sendOfferItemInfoToBackend(
    OfferItemPayload dto,
  ) async {
    try {
      await BackendOfferService.instance.sendOfferItem(dto);
    } catch (e, st) {
      Sentry.captureException(e);
      talker.error(e, st);
      rethrow;
    }
  }

  static Future<void> cancelOfferBackendRequest(String offerHash) async {
    try {
      await BackendOfferService.instance.cancelOffer(offerHash);
    } catch (e, st) {
      Sentry.captureException(e);
      talker.error(
        e,
        st,
      );
      rethrow;
    }
  }

  // backend encodes message and returns hash of typed data
  // TODO: Fix the type of the payload once json serialization changes are in
  static Future<RaribleHashAndEncodedData>
      getRaribleOfferTypedDataHashAndEncodedData(
    Map typedData,
    RaribleV2Order order,
  ) async {
    try {
      final result = await BackendOfferService.instance
          .getRaribleOfferTypedDataHashAndEncodedData(
        {
          'typedData': typedData,
          'message': order.toJson(),
        },
      );

      final data = jsonDecode(result.data);

      talker.debug(data);

      return RaribleHashAndEncodedData(
        data['typedDataHash'],
        data['encodedData'],
      );
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
