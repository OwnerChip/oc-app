import 'package:ownerchip_whitelabel/domain/app/appDto.dart';
import 'package:ownerchip_whitelabel/services/backend/app/backendApp.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// get all collections associated with the app (basis for filtering for MINTER_ROLE)
final appDtoProvider = FutureProvider.autoDispose<AppDto>((ref) async {
  // first, try to get the collections from the backend
  try {
    return await BackendApp.getApp();
  } catch (e, st) {
    Sentry.captureException(
      e,
      stackTrace: st,
    );
    talker.error(e, st);
    throw Exception("Error getting app data from backend: $e");
  }
});
