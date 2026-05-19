import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/services/backend/backend.services.dart';
import 'package:ownerchip_whitelabel/services/backend/collection/backendCollectionService.dart';
import 'package:ownerchip_whitelabel/services/backend/collection/payloads/sendCardLostPayload.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:web3dart/web3dart.dart';

abstract class BackendCollection extends Backend {

  static Future<List<Map>> getAllCollections() async {
    try {
      final response = await BackendCollectionService.instance
          .getAllCollections()
          .catchError((e) {
        Sentry.captureException(
          e,
        );
        talker.error(e);
        throw e;
      });

      return (response.data as List<dynamic>).map((e) => e as Map).toList();
    } catch (e) {
      Sentry.captureException(
        e,
      );
      talker.error(e);
      rethrow;
    }
  }

  static Future<bool> sendCardLostToBackend(EthereumAddress chipAddress,
      EthereumAddress collectionAddress,
      SignatureData chipSignature,
      String sessionId,
      String email,
      String name,
      String telNr) async {
    final service = BackendCollectionService.instance;
    try {
      service.recoverCollection(
          hex: collectionAddress.hex,
          body: SendCardLostPayload(
            chipAddress: chipAddress.hex,
            // TODO: define signature data type once Json_serializable branch is merged
            chipSignature: {
              'r': convertSignatureParamToHexString(chipSignature.signature.r),
              's': convertSignatureParamToHexString(chipSignature.signature.s),
              'v': chipSignature.signature.v,
            },
            sessionId: sessionId,
            email: email,
            name: name,
            telNr: telNr,
          ));
      return true;
    } catch (e, s) {
      Sentry.captureException(
        e,
        stackTrace: s,
      );
      talker.error(e, s);
      return false;
    }
  }

  static Future<void> recordTx(
    EthereumAddress collectionAddress, {
    required String txHash,
    required String senderAddress,
    required String metaTxAgreementId,
    required String functionSignature,
    String? callData,
    String? tokenId,
    String? transferId,
  }) async {
    try {
      final body = <String, dynamic>{
        'txHash': txHash,
        'senderAddress': senderAddress,
        'metaTxAgreementId': metaTxAgreementId,
        'functionSignature': functionSignature,
        if (callData != null) 'callData': callData,
        if (tokenId != null) 'tokenId': tokenId,
        if (transferId != null) 'transferId': transferId,
      };
      await BackendCollectionService.instance.recordTx(
        hex: collectionAddress.hex,
        body: body,
      );
    } catch (e, s) {
      Sentry.captureException(e, stackTrace: s);
      talker.error('Failed to record tx $txHash for ${collectionAddress.hex}: $e', s);
      rethrow;
    }
  }
}
