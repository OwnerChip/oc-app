import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/domain/app/appDto.dart';
import 'package:ownerchip_whitelabel/services/backend/app/backendAppService.dart';
import 'package:ownerchip_whitelabel/services/backend/app/payloads/sendAnalyticsPayload.dart';
import 'package:ownerchip_whitelabel/services/backend/backend.services.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

abstract class BackendApp extends Backend {
  // This function will post a user action to the analytics backend.
  static Future<void> sendAnalyticsTrace(
      String caseId, String description, String type,
      {Map<String, dynamic>? tags}) async {
    await BackendAppService.instance
        .sendAnalyticsEvent(
      payload: SendAnalyticsPayload(
        caseId: caseId,
        description: description,
        type: type,
        tags: jsonEncode(tags),
      ),
      packageName: dotenv.get('BITRISEIO_PACKAGE_NAME'),
    )
        .catchError((e) {
      Sentry.captureException(
        e,
      );
      talker.error(e);
    });
  }

  static Future<AppDto> getApp() async {
    try {
      final response = await BackendAppService.instance
          .getAppCollections(
        packageName: dotenv.get('BITRISEIO_PACKAGE_NAME'),
      )
          .catchError((e) {
        Sentry.captureException(
          e,
        );
        talker.error(e);
        throw e;
      });

      return AppDto.fromJson(response.data);
    } catch (e) {
      Sentry.captureException(
        e,
      );
      talker.error(e);
      rethrow;
    }
  }

  // get a list of all collections associated with a specific app
  // TODO: Define the return type after json_serialization PR is merged
  static Future<Map> getAppCollections() async {
    try {
      final response = await BackendAppService.instance
          .getAppCollections(
        packageName: dotenv.get('BITRISEIO_PACKAGE_NAME'),
      )
          .catchError((e) {
        Sentry.captureException(
          e,
        );
        talker.error(e);
        throw e;
      });

      return response.data;
    } catch (e) {
      Sentry.captureException(
        e,
      );
      talker.error(e);
      rethrow;
    }
  }
}
