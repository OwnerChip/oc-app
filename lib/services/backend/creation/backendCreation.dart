import 'package:ownerchip_whitelabel/domain/common/backendPaginationResponse.dart';
import 'package:ownerchip_whitelabel/domain/creation/digitalTwinMetadata.dart';
import 'package:ownerchip_whitelabel/services/backend/backend.services.dart';
import 'package:ownerchip_whitelabel/services/backend/creation/backendCreationService.dart';
import 'package:ownerchip_whitelabel/services/backend/creation/payloads/updateDigitalTwinCreationMetadataStatusPayload.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class BackendCreation extends Backend {

  ///
  /// Get the digital twins of the user
  /// param [page] the page number
  /// returns a [DigitalTwinMetadataPagination] object
  static Future<BackendPaginationResponse<DigitalTwinMetadata>> getMyDigitalTwins(
      int page) async {
    final service = BackendCreationService.instance;

    bool success = true;
    final res = await service.getMyDigitalTwins(page).catchError((error) {
      success = false;
      talker.error(error);
      Sentry.captureException(error, stackTrace: StackTrace.current);
    });

    if (!success) {
      throw Exception('Failed to get digital twins');
    }

    return res;
  }


  ///
  /// Update the status of a digital twin metadata
  /// param [id] the id of the digital twin metadata
  /// param [status] the new status
  /// returns a [bool] indicating if the operation was successful
  static Future<bool> updateDigitalTwinMetadataStatus(
    String id,
    DigitalTwinCreationMetadataStatus status,
  ) async {
    final service = BackendCreationService.instance;

    bool success = true;
    await service
        .updateStatus(
            id,
            UpdateDigitalTwinCreationMetadataStatusPayload(
              status: status,
            ))
        .catchError((error) {
      success = false;
      talker.error(error);
      Sentry.captureException(error, stackTrace: StackTrace.current);
    });

    if (!success) {
      throw Exception('Failed to update digital twin metadata status');
    }

    return true;
  }
}
