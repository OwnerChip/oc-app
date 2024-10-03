import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:ownerchip_whitelabel/domain/fcm/fcm_token.dart';
import 'package:ownerchip_whitelabel/services/backend/backend.services.dart';
import 'package:ownerchip_whitelabel/services/backend/fcm/backendFcmService.dart';
import 'package:ownerchip_whitelabel/services/backend/fcm/payloads/saveFcmTokenPayload.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

abstract class BackendFCM extends Backend {
  static Future<FCMToken?> getAndSaveFCMToken(String sessionId) async {
    FCMToken? fcmToken;

    try {
      final messagingToken = await FirebaseMessaging.instance.getToken();
      if (messagingToken != null) {
        fcmToken = await BackendFCM.saveFCMToken(
          token: messagingToken,
          sessionId: sessionId,
        );
      }
    } catch (e) {
      Sentry.captureException(e);
      talker.log('Error getting FCM token: $e');
    }

    return fcmToken;
  }

  static Future<FCMToken?> saveFCMToken({
    required String token,
    required String sessionId,
  }) async {
    FCMToken? fcm;
    await BackendFcmService.instance
        .saveFcmToken(
      body: SaveFCMTokenPayload(
        token: token,
        sessionId: sessionId,
      ),
    )
        .then((res) {
      fcm = res;
      talker.log('FCM token saved: ${fcm?.toJson()}');
    }).catchError((e) {
      Sentry.captureException(e);
      talker.log('Error saving FCM token: $e');
      fcm = null;
    });
    return fcm;
  }

  static Future<bool> deleteFCMToken(FCMToken token) async {
    bool success = true;
    await BackendFcmService.instance
        .deleteFcmToken(
      id: token.id,
    )
        .catchError((e) {
      Sentry.captureException(e);
      talker.log('Error deleting FCM token: $e');
      success = false;
    });

    return success;
  }
}
