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
  static Future<BackendPaginationResponse<DigitalTwinMetadata>?>
      getMyDigitalTwins(
    int page, {
    List<DigitalTwinCreationMetadataStatus> status = const [],
  }) async {
    final service = BackendCreationService.instance;

    bool success = true;
    final res = await service
        .getMyDigitalTwins(
      page,
      status.map((e) => DigitalTwinCreationMetadataStatusEnumMap[e]!).toList(),
    )
        .catchError((error) {
      success = false;
      talker.error(error);
      Sentry.captureException(error, stackTrace: StackTrace.current);
      return null;
    });

    if (!success) {
      throw Exception('Failed to get digital twins');
    }

    return res;
  }

  ///
  /// Mark a digital twin as minted
  /// param [id] the id of the digital twin
  /// param [chipId] the chip id of the digital twin
  /// returns a [bool] indicating if the operation was successful
  ///
  static Future<bool> markDigitalTwinAsMinted({
    required String id,
    required String chipId,
  }) async {
    final service = BackendCreationService.instance;

    bool success = true;
    await service
        .mintDigitalTwin(
      id,
      chipId,
    )
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
