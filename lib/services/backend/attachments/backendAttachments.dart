import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/services/backend/attachments/backendAttachmentsService.dart';
import 'package:ownerchip_whitelabel/services/backend/attachments/payloads/postAttachmentMetadataToBackendPayload.dart';
import 'package:ownerchip_whitelabel/services/backend/attachments/payloads/putAttachmentMetadataToBackendPayload.dart';
import 'package:ownerchip_whitelabel/services/backend/backend.services.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

abstract class BackendAttachments extends Backend {
// sends attachment metadata to backend; receives amazon s3 link if file, else "OK"
  static Future<List> postAttachmentMetadataToBackend(
      UserSession userSession,
      EthereumAddress walletAddress,
      int chainId,
      EthereumAddress collectionId,
      BigInt tokenId,
      String name,
      String title,
      bool isPrivate,
      {String? attachmentLink,
      String? fileHash,
      String? contentType,
      int? fileSize}) async {
    if (attachmentLink != null && !attachmentLink.startsWith('http')) {
      attachmentLink = 'https://$attachmentLink';
    }

    try {
      final response = await BackendAttachmentsService.instance
          .postAttachmentMetadataToBackend(
        payload: PostAttachmentMetadataToBackendPayload(
          auth: makeAuthObject(
            userSession.sessionId,
            userSession.signatureData,
            walletAddress,
            chainId,
            collectionId,
            tokenId,
          ),
          name: name,
          title: title,
          isPrivate: isPrivate,
          contentType: contentType,
          fileSize: fileSize,
          link: attachmentLink,
          sha256Hash: fileHash == null ? null : "0x$fileHash",
        ),
      )
          .catchError((e) {
        talker.error(e);
        throw e;
      });
      return response.data;
    } catch (e, st) {
      Sentry.captureException(e);
      talker.error(e, st);
      rethrow;
    }
  }

// sends attachment metadata to backend; receives amazon s3 link if file, else "OK"
  static Future<String> putAttachmentMetadataToBackend(
      UserSession userSession,
      EthereumAddress walletAddress,
      int chainId,
      EthereumAddress collectionId,
      BigInt tokenId,
      String fileUuid,
      String name,
      String title,
      bool isPrivate,
      {String? attachmentUrl}) async {
    final service = BackendAttachmentsService.instance;

    try {
      return await service
          .putAttachmentMetadataToBackend(
        payload: PutAttachmentMetadataToBackendPayload(
            auth: makeAuthObject(
              userSession.sessionId,
              userSession.signatureData,
              walletAddress,
              chainId,
              collectionId,
              tokenId,
            ),
            uuid: fileUuid,
            isPrivate: isPrivate,
            title: title,
            newLink: attachmentUrl),
      )
          .catchError((e) {
        talker.error(e);
        throw e;
      });
    } catch (e, st) {
      Sentry.captureException(e);
      talker.error(e, st);
      rethrow;
    }
  }

//upload file to aws presigned url
  static Future<dynamic> uploadFileToAWS(
    File file,
    String uploadUrl,
    String contentType,
  ) async {
    final Dio dio = Dio();
    try {
      final bytes = await file.readAsBytes();
      final response = await dio.put(uploadUrl,
          data: bytes, options: Options(contentType: contentType));
      return response;
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      talker.error(e, st);
      rethrow;
    }
  }

//remove attachment
  static Future<dynamic> deleteAttachmentFromBackend(
    UserSession userSession,
    EthereumAddress walletAddress,
    int chainId,
    EthereumAddress collectionId,
    BigInt tokenId,
    String fileUuid,
  ) async {
    try {
      final result = await BackendAttachmentsService.instance
          .deleteAttachmentMetadataFromBackend(
        uuid: fileUuid,
        auth: makeAuthObject(
          userSession.sessionId,
          userSession.signatureData,
          walletAddress,
          chainId,
          collectionId,
          tokenId,
        ),
      )
          .catchError((e) {
        talker.error(e);
        throw e;
      });
      return result.data;
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      talker.error(e, st);
      rethrow;
    }
  }

//funciton that makes auth object for requests
  static Map<String, dynamic> makeAuthObject(
    String sessionId,
    MsgSignature userSignature,
    EthereumAddress walletAddress,
    int chainId,
    EthereumAddress collectionId,
    BigInt tokenId,
  ) {
    return {
      'sessionId': sessionId,
      'tokenId': convertTokenIdToEthereumAddress(tokenId),
      'collectionId': collectionId.toString(),
      'chainId': chainId,
      'walletAddress': walletAddress.toString(),
      'userWalletSignature': {
        'r': convertSignatureParamToHexString(userSignature.r),
        's': convertSignatureParamToHexString(userSignature.s),
        'v': userSignature.v
      },
    };
  }

//GET request for /files/{tokenId}/public
  static Future<dynamic> getPublicAttachmentsFromBackend(
    BigInt tokenId,
  ) async {
    try {
      final result = await BackendAttachmentsService.instance
          .getPublicAttachmentsFromBackend(
        uuid: convertTokenIdToEthereumAddress(tokenId),
      )
          .catchError((e) {
        talker.error(e);
        throw e;
      });
      return result;
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      talker.error(e, st);
      rethrow;
    }
  }

  static Future<dynamic> getPublicAndPrivateAttachmentsFromBackend(
    UserSession userSession,
    EthereumAddress walletAddress,
    int chainId,
    EthereumAddress collectionId,
    BigInt tokenId,
  ) async {
    try {
      final result = await BackendAttachmentsService.instance
          .getPublicAndPrivateAttachmentsFromBackend(
        auth: makeAuthObject(
          userSession.sessionId,
          userSession.signatureData,
          walletAddress,
          chainId,
          collectionId,
          tokenId,
        ),
      )
          .catchError((e) {
        talker.error(e);
        throw e;
      });

      return result;
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      talker.error(e, st);
      rethrow;
    }
  }

  static Future<dynamic> deleteAllAttachments(
    UserSession userSession,
    EthereumAddress walletAddress,
    int chainId,
    EthereumAddress collectionId,
    BigInt tokenId,
    SignatureData tokenSignatureData,
  ) async {
    try {
      final result = await BackendAttachmentsService.instance
          .deleteAllAttachments(
              auth: makeAuthObject(
        userSession.sessionId,
        userSession.signatureData,
        walletAddress,
        chainId,
        collectionId,
        tokenId,
      ))
          .catchError((e) {
        talker.error(e);
        throw e;
      });

      return result;
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      talker.error(e, st);
      rethrow;
    }
  }
}
