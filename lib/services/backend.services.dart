import 'package:web3dart/web3dart.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// get OC backend client
Dio getBackendClient() {
  return Dio(BaseOptions(
      baseUrl: dotenv.get('OC_BACKEND_URL'),
      headers: {"app_id": dotenv.get('BITRISEIO_PACKAGE_NAME'), "lang": "en"}));
}

// Checks if a gasless transaction is supported by a collection.
// Returns a tuple of [bool, String].
// bool: true if a meta transaction is supported, false otherwise.
// String: the id of the meta transaction agreement if it is supported.
//         the error message if it is not supported.
Future<List<dynamic>> checkMetaTx(
    EthereumAddress collectionId, String functionSignatureHash) async {
  final Dio dio = getBackendClient();
  final String url = '/collection/$collectionId/metaTx/$functionSignatureHash';
  try {
    final response = await dio.get(url);
    final String metaTxAgreementId = response.data;
    return [true, metaTxAgreementId];
  } catch (e) {
    return [false, e];
  }
}

// This function will send a gasless request to the backend. The backend will then
// send a meta transaction to the network.
Future<String> sendGaslessRequest(
    EthereumAddress collectionId,
    String txSignature,
    String metaTxAgreementId,
    Map<String, dynamic> txRequest) async {
  final Dio dio = getBackendClient();
  final String url = '/collection/$collectionId/metatx';
  //make post request with dio
  final response = await dio.post(url, data: {
    "txSignature": txSignature,
    "metaTxAgreementId": metaTxAgreementId,
    "txRequest": txRequest
  });
  return response.data; //txId
}
