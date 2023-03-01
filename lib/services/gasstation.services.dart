import 'dart:typed_data';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'package:ownerchip_whitelabel/services/web3.services.dart';
import 'package:ownerchip_whitelabel/config/chains.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';

final EIP712Domain = [
  {'name': 'name', 'type': 'string'},
  {'name': 'version', 'type': 'string'},
  {'name': 'verifyingContract', 'type': 'address'},
];

final ForwardRequest = [
  {'name': 'message', 'type': 'string'},
  {'name': 'from', 'type': 'address'},
  {'name': 'to', 'type': 'address'},
  {'name': 'value', 'type': 'uint256'},
  {'name': 'gas', 'type': 'uint256'},
  {'name': 'nonce', 'type': 'uint256'},
  {'name': 'data', 'type': 'bytes'},
];

Map<String, dynamic> getMetaTxTypeData(int chainId) {
  final String verifyingContract = chainConfig[chainId]!.forwarderContract!;
  return {
    'types': {
      'EIP712Domain': EIP712Domain,
      'ForwardRequest': ForwardRequest,
    },
    'domain': {
      'name': 'MinimalForwarder',
      'version': '0.0.1',
      'verifyingContract': verifyingContract,
    },
    'primaryType': 'ForwardRequest',
  };
}

Future<Map<String, dynamic>> buildTypedV4Request(
    String functionSignatureHash,
    String chainRpcUrl,
    int chainId,
    Uint8List tokenIdHash,
    MsgSignature signature,
    String? tokenURI,
    EthereumAddress from,
    EthereumAddress to) async {
  final String verifyingContract = chainConfig[chainId]!.forwarderContract!;
  String data;
  if (functionSignatureHash == gaslessMintFunctionSignature) {
    data =
        makeMintData(functionSignatureHash, tokenIdHash, signature, tokenURI!);
  } else if (functionSignatureHash == gaslessBurnFunctionSignature) {
    data = makeBurnData(functionSignatureHash, tokenIdHash, signature);
  } else {
    throw Exception('Invalid function signature hash');
  }
  final BigInt nonce = await getNonce(chainRpcUrl, verifyingContract, from.hex);
  return {
    'message':
        'Please sign this message, so OwnerChip can send this transaction on your behalf.',
    'from': from.hex,
    'to': to.hex,
    'value': 0,
    'gas':
        250000, //gas actually used by mint or burn TX is approx. 200k; this can stay hard coded
    'nonce': nonce.toInt(),
    'data': data,
  };
}

Future<Map<String, dynamic>> buildTypedData(int chainId, request) async {
  final typeData = getMetaTxTypeData(chainId);
  return {...typeData, 'message': request};
}

Future<List<Map<String, dynamic>>> makeGaslessParams({
  required String functionSignatureHash,
  required String chainRpcUrl,
  required int chainId,
  required Uint8List tokenIdHash,
  required MsgSignature signature,
  required EthereumAddress from,
  required EthereumAddress to,
  String? tokenURI,
}) async {
  final request = await buildTypedV4Request(functionSignatureHash, chainRpcUrl,
      chainId, tokenIdHash, signature, tokenURI, from, to);
  final typedData = await buildTypedData(chainId, request);
  return [typedData, request];
}
