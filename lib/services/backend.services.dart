import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'package:dio/dio.dart';
import 'package:ownerchip_whitelabel/services/providers.service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// get OC backend client
Dio getBackendClient() {
  return Dio(BaseOptions(
      baseUrl: dotenv.get('OC_BACKEND_URL'),
      headers: {"app_id": dotenv.get('BITRISEIO_PACKAGE_NAME'), "lang": "en"}));
}

Future<List<dynamic>> checkMetaTx(
    EthereumAddress collectionId, String functionSignatureHash) async {
  final Dio dio = getBackendClient();
  // final String url = '/collection/$collectionId/metaTx/$functionSignatureHash';
  final String url =
      '/collection/0x0398B9b7Edb259E838a197Dd84752D9471522C54/metaTx/$functionSignatureHash';
  try {
    final response = await dio.get(url);
    final String metaTxAgreementId = response.data;
    return [true, metaTxAgreementId];
  } catch (e) {
    return [false, e];
  }
}

Future<String> sendGaslessRequest(
    EthereumAddress collectionId,
    String txSignature,
    String functionSignature,
    String metaTxAgreementId,
    Map<String, dynamic> txRequest) async {
  final Dio dio = getBackendClient();
  // final String url = '/collection/$collectionId/metatx';
  const String url =
      '/collection/0x0398B9b7Edb259E838a197Dd84752D9471522C54/metatx';
  //make post request with dio
  final response = await dio.post(url, data: {
    "txSignature": txSignature,
    "functionSignatureHash": functionSignature,
    "metaTxAgreementId": metaTxAgreementId,
    "txRequest": txRequest
  });
  return response.data; //txId
}
