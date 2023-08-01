import 'package:dio/dio.dart';
import 'package:ownerchip_whitelabel/services/backend.services.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'dart:io';
import 'package:crypto/crypto.dart';

// sends attachment metadata to backend; receives amazon s3 link if file, else "OK"
Future<List> postAttachmentMetadataToBackend(
    EthereumAddress walletAddress,
    int chainId,
    EthereumAddress collectionId,
    BigInt tokenId,
    SignatureData tokenSignatureData,
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
      walletAddress,
      chainId,
      collectionId,
      tokenId,
      tokenSignatureData,
    ),
    'name': name,
    'title': title,
    'size': fileSize,
    'content_type': contentType,
    'sha256_hash': fileHash,
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
    EthereumAddress walletAddress,
    int chainId,
    EthereumAddress collectionId,
    BigInt tokenId,
    SignatureData tokenSignatureData,
    String fileUuid,
    String name,
    String title,
    bool isPrivate,
    {String? attachmentUrl}) async {
  final Dio dio = getBackendClient();

  const String url = '/attachments';
  final data = {
    'auth': makeAuthObject(
      walletAddress,
      chainId,
      collectionId,
      tokenId,
      tokenSignatureData,
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
    return response.data;
  } catch (e) {
    print(e);
    rethrow;
  }
}

//remove attachment
Future<dynamic> deleteAttachmentFromBackend(
  EthereumAddress walletAddress,
  int chainId,
  EthereumAddress collectionId,
  BigInt tokenId,
  SignatureData tokenSignatureData,
  String fileUuid,
) async {
  final Dio dio = getBackendClient();
  final url = '/attachments/$fileUuid';

  try {
    final result = await dio.delete(url,
        data: makeAuthObject(
          walletAddress,
          chainId,
          collectionId,
          tokenId,
          tokenSignatureData,
        ));

    return result;
  } catch (e) {
    print(e);
    rethrow;
  }
}

//funciton that makes auth object for requests
Map<String, dynamic> makeAuthObject(
  EthereumAddress walletAddress,
  int chainId,
  EthereumAddress collectionId,
  BigInt tokenId,
  SignatureData tokenSignatureData,
) {
  return {
    'sessionId': '1234', //TODO: insert real session id
    'requestedRole': 'CREATOR',
    'chipSignature': {
      'r': "0x" + tokenSignatureData.signature.r.toRadixString(16),
      's': "0x" + tokenSignatureData.signature.s.toRadixString(16),
      'v': 27
    },
    'chipSignatureMessageDigest':
        bytesToHex(tokenSignatureData.hashedMsg, include0x: true),
    'tokenId': "0x" + tokenId.toRadixString(16),
    'collectionId': collectionId.toString(),
    'chainId': chainId,
    'walletAddress': walletAddress.toString(),
    'userWalletSignature': {
      'r': '0x083161fbe4c83ccf8c982b674e62eae2d2ff682297878fdb9f13eb93b5213a9f',
      's': '0x243473d1da0f9d515a03227a20932d9bf2a0d7b243d51835097306651fce11db',
      'v': 27
    },
    'userSignatureMessageDigest':
        '0x55e564f2b85a019871f4cfde00eb60d91c8d551a850c8945d5a32201063ce618'
  };
}

//GET request for /files/{tokenId}/public
Future<dynamic> getPublicAttachmentsFromBackend(
  BigInt tokenId,
) async {
  final Dio dio = getBackendClient();
  final url = '/attachments/${"0x${tokenId.toRadixString(16)}"}/public';
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
  EthereumAddress walletAddress,
  int chainId,
  EthereumAddress collectionId,
  BigInt tokenId,
  SignatureData tokenSignatureData,
) async {
  final Dio dio = getBackendClient();
  const url = '/attachments/owner/view-all';

  try {
    final result = await dio.post(url,
        data: makeAuthObject(
          walletAddress,
          chainId,
          collectionId,
          tokenId,
          tokenSignatureData,
        ));

    return result;
  } catch (e) {
    print(e);
    rethrow;
  }
}

Future<dynamic> deleteAllAttachments(
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
          walletAddress,
          chainId,
          collectionId,
          tokenId,
          tokenSignatureData,
        ));

    return result;
  } catch (e) {
    print(e);
    rethrow;
  }
}
