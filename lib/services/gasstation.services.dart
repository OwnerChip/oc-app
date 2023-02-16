import 'dart:typed_data';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'package:ownerchip_whitelabel/services/web3.services.dart';
import 'package:ownerchip_whitelabel/config/chains.dart';

final EIP712Domain = [
  {'name': 'name', 'type': 'string'},
  {'name': 'version', 'type': 'string'},
  {'name': 'chainId', 'type': 'uint256'},
  {'name': 'verifyingContract', 'type': 'address'},
];

final ForwardRequest = [
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
      'chainId': chainId,
      'verifyingContract': verifyingContract,
    },
    'primaryType': 'ForwardRequest',
  };
}

Future<Map<String, dynamic>> buildRequest(
    String chainRpcUrl,
    Uint8List tokenIdHash,
    MsgSignature signature,
    String tokenURI,
    EthereumAddress from,
    EthereumAddress to) async {
  final web3client = getWeb3Client(chainRpcUrl);
  final String data = makeMintData(tokenIdHash, signature, tokenURI);
  final nonce = await web3client.getTransactionCount(from);
  return {
    'contents': 'Hello, Bob yo!', //TODO: replace wither externalized string
    'value': 0,
    'gas': 1000000, //TODO: replace default value by something else??
    'nonce': nonce,
    'from': from.hex,
    'to': to.hex,
    'data': data,
  };
}

Future<Map<String, dynamic>> buildTypedData(int chainId, request) async {
  final typeData = getMetaTxTypeData(chainId);
  return {...typeData, 'message': request};
}

Future<Map<String, dynamic>> makeGaslessMintParams(
    String chainRpcUrl,
    int chainId,
    Uint8List tokenIdHash,
    MsgSignature signature,
    String tokenURI,
    EthereumAddress from,
    EthereumAddress to) async {
  final request = await buildRequest(
      chainRpcUrl, tokenIdHash, signature, tokenURI, from, to);
  final typedData = await buildTypedData(chainId, request);
  return typedData;
}
