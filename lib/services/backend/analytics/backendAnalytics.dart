import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/services/backend/analytics/backendAnalyticsService.dart';
import 'package:ownerchip_whitelabel/services/backend/analytics/payloads/sendAnalyticsPayload.dart';
import 'package:ownerchip_whitelabel/services/backend/backend.services.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

abstract class BackendAnalytics extends Backend {
  // This function will post a user action to the analytics backend.
  static Future<void> sendAnalyticsTrace(
      String caseId, String description, String type,
      {Map<String, dynamic>? tags}) async {
    await BackendAnalyticsService.instance
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
}
