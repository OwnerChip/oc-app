import 'package:dio/dio.dart';
import 'package:ownerchip_whitelabel/services/backend.services.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'dart:io';
import 'package:crypto/crypto.dart';

// sends attachment metadata to backend; receives amazon s3 link if file, else "OK"
Future<List> postAttachmentMetadataToBackend(
    BackendSession backendSession,
    EthereumAddress walletAddress,
    int chainId,
    EthereumAddress collectionId,
    BigInt tokenId,
    String name,
    String title,
    bool isPrivate,
    {String? fileLink,
    String? fileHash,
    String? contentType,
    int? fileSize}) async {
  final Dio dio = getBackendClient();

  final url = '/attachments';
  final data = {
    'auth': makeAuthObject(
      backendSession.sessionId,
      backendSession.signatureData,
      walletAddress,
      chainId,
      collectionId,
      tokenId,
    ),
    'name': name,
    'title': title,
    'size': fileSize,
    'content_type': contentType,
    'sha256_hash': fileHash == null ? null : "0x$fileHash",
    'is_private': isPrivate,
    'link': fileLink,
  };

  try {
    final response = await dio.post(url, data: data);
    return response.data;
  } catch (e) {
    //TODO: send analytics to sentry
    print(e);
    rethrow;
  }
}

// sends attachment metadata to backend; receives amazon s3 link if file, else "OK"
Future<String> putAttachmentMetadataToBackend(
    BackendSession backendSession,
    EthereumAddress walletAddress,
    int chainId,
    EthereumAddress collectionId,
    BigInt tokenId,
    String fileUuid,
    String name,
    String title,
    bool isPrivate,
    {String? attachmentUrl}) async {
  final Dio dio = getBackendClient();

  const String url = '/attachments';
  final data = {
    'auth': makeAuthObject(
      backendSession.sessionId,
      backendSession.signatureData,
      walletAddress,
      chainId,
      collectionId,
      tokenId,
    ),
    'uuid': fileUuid,
    'is_private': isPrivate,
    'new_title': title,
    'new_link': attachmentUrl,
  };

  try {
    final response = await dio.put(url, data: data);
    return response.data;
  } catch (e) {
    //TODO: send analytics to sentry
    print(e);
    rethrow;
  }
}

//upload file to aws presigned url
Future<dynamic> uploadFileToAWS(
    File file, String uploadUrl, String contentType) async {
  final Dio dio = Dio();
  try {
    final bytes = await file.readAsBytes();
    final response = await dio.put(uploadUrl,
        data: bytes, options: Options(contentType: contentType));
    return response;
  } catch (e) {
    print(e);
    rethrow;
  }
}

//remove attachment
Future<dynamic> deleteAttachmentFromBackend(
  BackendSession backendSession,
  EthereumAddress walletAddress,
  int chainId,
  EthereumAddress collectionId,
  BigInt tokenId,
  String fileUuid,
) async {
  final Dio dio = getBackendClient();
  final url = '/attachments/$fileUuid';

  try {
    final result = await dio.delete(url,
        data: makeAuthObject(
          backendSession.sessionId,
          backendSession.signatureData,
          walletAddress,
          chainId,
          collectionId,
          tokenId,
        ));

    return result;
  } catch (e) {
    print(e);
    rethrow;
  }
}

//funciton that makes auth object for requests
Map<String, dynamic> makeAuthObject(
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
Future<dynamic> getPublicAttachmentsFromBackend(
  BigInt tokenId,
) async {
  final Dio dio = getBackendClient();
  final url = '/attachments/${convertTokenIdToEthereumAddress(tokenId)}/public';
  try {
    final result = await dio.get(
      url,
    );
    return result;
  } catch (e) {
    print(e);
    rethrow;
  }
}

Future<dynamic> getPublicAndPrivateAttachmentsFromBackend(
  BackendSession backendSession,
  EthereumAddress walletAddress,
  int chainId,
  EthereumAddress collectionId,
  BigInt tokenId,
) async {
  final Dio dio = getBackendClient();
  const url = '/attachments/owner/view-all';

  try {
    final result = await dio.post(url,
        data: makeAuthObject(
          backendSession.sessionId,
          backendSession.signatureData,
          walletAddress,
          chainId,
          collectionId,
          tokenId,
        ));

    return result;
  } catch (e) {
    print(e);
    rethrow;
  }
}

Future<dynamic> deleteAllAttachments(
  BackendSession backendSession,
  EthereumAddress walletAddress,
  int chainId,
  EthereumAddress collectionId,
  BigInt tokenId,
  SignatureData tokenSignatureData,
) async {
  final Dio dio = getBackendClient();
  const url = '/attachments';

  try {
    final result = await dio.delete(url,
        data: makeAuthObject(
          backendSession.sessionId,
          backendSession.signatureData,
          walletAddress,
          chainId,
          collectionId,
          tokenId,
        ));

    return result;
  } catch (e) {
    print(e);
    rethrow;
  }
}
