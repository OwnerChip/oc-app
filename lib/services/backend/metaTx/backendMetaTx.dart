import 'package:ownerchip_whitelabel/services/backend/backend.services.dart';
import 'package:ownerchip_whitelabel/services/backend/metaTx/backendMetaTxService.dart';
import 'package:ownerchip_whitelabel/services/backend/metaTx/payloads/sendGaslessRequestPayload.dart';
import 'package:web3dart/web3dart.dart';

abstract class BackendMetaTx extends Backend {
  // Checks if a gasless transaction is supported by a collection.
  // Returns a tuple of [bool, String].
  // bool: true if a meta transaction is supported, false otherwise.
  // String: the id of the meta transaction agreement if it is supported.
  //         the error message if it is not supported.
  static Future<List<dynamic>> checkMetaTx(
    EthereumAddress collectionId,
    String functionSignatureHash,
  ) async {
    // return [false, ""];

    return await BackendMetaTxService.instance
        .checkMetaTx(
            collectionId: collectionId.hex,
            functionSignatureHash: functionSignatureHash)
        .then((e) {
      return [true, e];
    }, onError: (e) {
      return [false, e.toString()];
    });
  }

  // This function will send a gasless request to the backend. The backend will then
  // send a meta transaction to the network.
  static Future<String> sendGaslessRequest(
    EthereumAddress collectionId,
    String txSignature,
    String metaTxAgreementId,
    Map<String, dynamic> txRequest,
  ) async {
    return BackendMetaTxService.instance.sendGaslessRequest(
      collectionId: collectionId.hex,
      body: SendGaslessRequestPayload(
          txSignature: txSignature,
          metaTxAgreementId: metaTxAgreementId,
          txRequest: txRequest),
    );
  }

  // gets the hash that needs to be used to sign a gasless tx request.
  static Future<String> getEthSignTypedDataSignature(
      EthereumAddress collectionId, Map<String, dynamic> txRequest) async {
    return BackendMetaTxService.instance
        .getEthSignTypedDataSignature(
      collectionId: collectionId.hex,
      body: txRequest,
    )
        .catchError((e) {
      throw e;
    });
  }
}
