import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web3dart/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'utils.dart';

Web3Client getWeb3Client() {
  var rpcUrl = dotenv.get('CHAIN_RPC');
  var client = Web3Client(rpcUrl, Client());
  return client;
}

Future<DeployedContract> getContract() async {
  String abi =
      await rootBundle.loadString("assets/contracts/contract.abi.json");
  DeployedContract contract = DeployedContract(
    ContractAbi.fromJson(abi, dotenv.get('CONTRACT_NAME')),
    EthereumAddress.fromHex(dotenv.get('CONTRACT_ADDRESS')),
  );
  return contract;
}

Future<List<dynamic>> query(String functionName, List<dynamic> args) async {
  DeployedContract contract = await getContract();
  ContractFunction function = contract.function(functionName);
  final web3Client = getWeb3Client();
  List<dynamic> result = await web3Client.call(
      contract: contract, function: function, params: args);
  return result;
}

// contract version 2
Future<bool> verifyTokenSigner(String chipWalletAddressHex,
    Uint8List tokenIdHash, MsgSignature signature) async {
  Uint8List r = bytesFromBigInt(signature.r);
  Uint8List s = bytesFromBigInt(signature.s);
  try {
    var result =
        await query("getSigner", [tokenIdHash, r, s, BigInt.from(signature.v)]);
    bool res = (chipWalletAddressHex == result[0].toString().toLowerCase());
    return res;
  } catch (e) {
    print("getSigner ERROR: $e");
    return false;
  }
}

// contract version 2
List<dynamic> makeSignedMintParams(String? from, Uint8List tokenIdHash,
    String tokenURI, MsgSignature signature,
    {String? gasPrice}) {
  String data = "0xcb5a7173" +
      uint8ListTo32ByteHex(tokenIdHash) + //bytes32
      "a0".padLeft(64, '0') + //string prefix
      signature.r.toRadixString(16).padLeft(64, '0') + //bytes32
      signature.s.toRadixString(16).padLeft(64, '0') + //bytes32
      signature.v.toRadixString(16).padLeft(64, '0') + //uint8
      (tokenURI.length).toRadixString(16).padLeft(64, '0') +
      stringToHex(tokenURI); //string;
  final params = [
    {
      "from": from,
      "to": dotenv.env['CONTRACT_ADDRESS'],
      "data": data,
      "gasPrice": gasPrice ?? dotenv.get('DEFAULT_GAS_PRICE'),
      "gas": "0x30D40",
    },
  ];
  return params;
}

// contract version 2
List<dynamic> makeSignedBurnParams(
    String? from, Uint8List tokenIdHash, MsgSignature signature,
    {String? gasPrice}) {
  String data = "0x469fd767" +
      uint8ListTo32ByteHex(tokenIdHash) +
      signature.r.toRadixString(16).padLeft(64, '0') +
      signature.s.toRadixString(16).padLeft(64, '0') +
      signature.v.toRadixString(16).padLeft(64, '0');
  final params = [
    {
      "from": from,
      "to": dotenv.env['CONTRACT_ADDRESS'],
      "data": data,
      "gasPrice": gasPrice ?? dotenv.get('DEFAULT_GAS_PRICE'),
      "gas": "0x30D40",
    },
  ];
  return params;
}

// wallet specific
dynamic makeWatchAssetParams(String imageUri) {
  final params = [
    {
      "type": "ERC721",
      "options": {
        "address": dotenv.get("CONTRACT_ADDRESS"),
        "symbol": "OCDemo",
        "decimals": 0,
        "image": imageUri
      }
    }
  ];
  return params;
}

Future<dynamic> getOwner(BigInt tokenId) async {
  try {
    var owner = await query("ownerOf", [tokenId]);
    print(owner);
    return owner[0];
  } catch (e) {
    print('Error while fetching owner of tokenId $tokenId: $e');
    return e;
  }
}

Future<dynamic> getTokenUri(BigInt tokenId) async {
  try {
    var uri = await query("tokenURI", [tokenId]);
    print(uri);
    return uri[0];
  } catch (e) {
    print('Error while fetching uri of tokenId $tokenId: $e');
    return e;
  }
}

Future<dynamic> getTxnReceipt(String txnHash) async {
  final web3Client = getWeb3Client();

  try {
    var txnReceipt = await web3Client.getTransactionReceipt(txnHash);
    while (txnReceipt == null) {
      txnReceipt = await web3Client.getTransactionReceipt(txnHash);
    }
    return txnReceipt;
  } catch (e) {
    print('Error while fetching txn receipt: $e');
    return e;
  }
}
