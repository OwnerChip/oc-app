import 'package:dio/dio.dart';
import 'package:ownerchip_whitelabel/domain/common/backendPaginationResponse.dart';
import 'package:ownerchip_whitelabel/domain/creation/digitalTwinAttachment.dart';
import 'package:ownerchip_whitelabel/domain/creation/digitalTwinMetadata.dart';
import 'package:ownerchip_whitelabel/services/backend/backend.services.dart';
import 'package:ownerchip_whitelabel/services/backend/creation/backendCreationService.dart';
import 'package:ownerchip_whitelabel/services/backend/creation/payloads/restoreDigitalTwinCreationPayload.dart';
import 'package:ownerchip_whitelabel/services/backend/creation/payloads/uploadDigitalTwinCreationAttachmentPayload.dart';
import 'package:ownerchip_whitelabel/services/backend/creation/responses/uploadDigitalTwinCreationAttachmentResponse.dart';
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
    int limit = 10,
    List<DigitalTwinCreationMetadataStatus> status = const [],
  }) async {
    final service = BackendCreationService.instance;

    bool success = true;
    final res = await service
        .getMyDigitalTwins(
      page,
      limit,
      status.map((e) => DigitalTwinCreationMetadataStatusEnumMap[e]!).toList(),
    )
        .catchError((error) {
      success = false;
      talker.error(error);
      // Sentry.captureException(error, stackTrace: StackTrace.current);
      return null;
    });

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

  static Future<DigitalTwinMetadata?> getDigitalTwinByTokenId({
    required String tokenId,
  }) async {
    final service = BackendCreationService.instance;

    bool success = true;
    final res = await service
        .getDigitalTwinByTokenId(
      tokenId,
    )
        .catchError((error) {
      success = false;
      talker.error(error);
      Sentry.captureException(error, stackTrace: StackTrace.current);
      return null;
    });

    return res;
  }

  static Future<List<DigitalTwinAttachment>?> getDigitalTwinAttachments({
    required String id,
  }) async {
    final service = BackendCreationService.instance;

    bool success = true;
    final res = await service
        .getDigitalTwinAttachments(
      id,
    )
        .catchError((error) {
      success = false;
      talker.error(error);
      Sentry.captureException(error, stackTrace: StackTrace.current);
      return null;
    });

    if (!success) {
      throw Exception('Failed to get digital twin attachments');
    }

    return res!;
  }

  static Future<bool> updateAttachmentMetadata({
    required String metadata,
    required String attachmentId,
    required UploadDigitalTwinCreationAttachmentPayload payload,
  }) async {
    final service = BackendCreationService.instance;

    bool success = true;
    await service
        .updateAttachmentMetadata(
      metadata,
      attachmentId,
      payload,
    )
        .catchError((error) {
      success = false;
      talker.error(error);
      Sentry.captureException(error, stackTrace: StackTrace.current);
    });

    if (!success) {
      throw Exception('Failed to update attachment metadata');
    }

    return true;
  }

  static Future<UploadDigitalTwinCreationAttachmentResponse?>
      prepareAttachmentUpload({
    required String id,
    required UploadDigitalTwinCreationAttachmentPayload payload,
  }) async {
    final service = BackendCreationService.instance;
    return await service
        .prepareAttachmentUpload(
      id,
      payload,
    )
        .catchError((error) {
      talker.error(error);
      Sentry.captureException(error, stackTrace: StackTrace.current);

      return null;
    });
  }

  static Future<void> setAttachmentUploaded({
    required String id,
    required String attachmentId,
  }) async {
    final service = BackendCreationService.instance;

    await service
        .setAttachmentUploaded(
      id,
      attachmentId,
    )
        .catchError((error) {
      talker.error(error);
      Sentry.captureException(error, stackTrace: StackTrace.current);
    });
  }

  static Future<bool> deleteAttachment({
    required String id,
    required String attachmentId,
  }) async {
    final service = BackendCreationService.instance;

    bool success = true;
    await service
        .deleteAttachmentMetadata(
      id,
      attachmentId,
    )
        .catchError((error) {
      success = false;
      talker.error(error);
      Sentry.captureException(error, stackTrace: StackTrace.current);
    });

    if (!success) {
      throw Exception('Failed to delete attachment metadata');
    }

    return true;
  }

  static Future<bool> prepareBurnDigitalTwin({
    required String id,
  }) async {
    final service = BackendCreationService.instance;

    bool success = true;
    await service
        .prepareBurnDigitalTwin(
      id,
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

  static Future<bool> cancelBurnDigitalTwin({
    required String id,
  }) async {
    final service = BackendCreationService.instance;

    bool success = true;
    await service
        .cancelBurnDigitalTwin(
      id,
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

  static Future<bool> markDigitalTwinAsBurned({
    required String id,
  }) async {
    final service = BackendCreationService.instance;

    bool success = true;
    await service
        .burnDigitalTwin(
      id,
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

  static Future<bool> prepareTransferDigitalTwin({
    required String id,
  }) async {
    final service = BackendCreationService.instance;

    bool success = true;
    await service
        .prepareTransferDigitalTwin(
      id,
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

  static Future<bool> cancelTransferDigitalTwin({
    required String id,
  }) async {
    final service = BackendCreationService.instance;

    bool success = true;
    await service
        .cancelTransferDigitalTwin(
      id,
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

  static Future<bool> markDigitalTwinAsTransferred({
    required String id,
    required String recipient,
  }) async {
    final service = BackendCreationService.instance;

    bool success = true;
    await service
        .transferDigitalTwin(
      id,
      recipient,
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

  static Future<String?> restoreDigitalTwinCreation({
    required String id,
    required String tokenId,
  }) async {
    final service = BackendCreationService.instance;
    bool success = true;
    String? error;
    final res = await service
        .restoreDigitalTwin(
      id,
      RestoreDigitalTwinCreationPayload(
        tokenId: tokenId,
      ),
    )
        .catchError((e) {
      success = false;
      if (e is DioException) {
        error = e.response?.data["detail"];
      }
      talker.error(error);
      Sentry.captureException(e, stackTrace: StackTrace.current);
      return null;
    });

    if (res?.response.statusCode != 200) {
      success = false;
      if (res != null && res.data is Map && res.data.containsKey("detail")) {
        error = res.data["detail"];
      }
    }

    return error;
  }
}
