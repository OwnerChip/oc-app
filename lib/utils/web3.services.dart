import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
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

Future<bool> verifyTokenSigner(String chipWalletAddressHex,
    Uint8List tokenIdHash, MsgSignature signature) async {
  Uint8List r = Uint8List.fromList(utf8.encode(signature.r.toString()));
  Uint8List s = Uint8List.fromList(utf8.encode(signature.s.toString()));
  Uint8List v = Uint8List.fromList(utf8.encode(signature.v.toString()));
  var bytes = BytesBuilder();
  bytes.add(tokenIdHash);
  bytes.add(r);
  bytes.add(s);
  bytes.add(v);
  Uint8List data = bytes.toBytes();
  try {
    var result = await query("getSigner", keccak256(data));
    bool res = (chipWalletAddressHex == result[0]);
    return res;
  } catch (e) {
    print("getSigner ERROR: $e");
    return false;
  }
}

List<dynamic> makeSignedBurnParams(
    String? from, Uint8List tokenIdHash, MsgSignature signature,
    {String? gasPrice}) {
  String data = "0x" +
      '42966c68' +
      getEthereumAddressFromUint8List(tokenIdHash) +
      signature.r.toString() +
      signature.s.toString() +
      signature.v.toString();
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

List<dynamic> makeSignedMintParams(String? from, Uint8List tokenIdHash,
    String tokenURI, MsgSignature signature,
    {String? gasPrice}) {
  String data = "0x" +
      "ba7aef43" +
      "60".padLeft(64, '0') +
      (tokenURI.length).toRadixString(16).padLeft(64, '0') +
      stringToHex(tokenURI) +
      signature.r.toString() +
      signature.s.toString() +
      signature.v.toString();
  ;
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

String makeMintTransactionData(
    String receivingWalletAddress, String tokenURI, Uint8List cardId) {
  String from = receivingWalletAddress.substring(2).padLeft(64, '0');
  String tokenURILocation = "60".padLeft(64, '0');
  String tokenId = uint8ListTo32ByteHex(cardId);
  String tokenUriLength = (tokenURI.length).toRadixString(16).padLeft(64, '0');
  String tokenURIHex = stringToHex(tokenURI);
  String data = "0x" +
      "ba7aef43" +
      from +
      tokenURILocation +
      tokenId +
      tokenUriLength +
      tokenURIHex;
  return data;
}

dynamic makeMintParams(
    String from, String to, String tokenURI, Uint8List cardId,
    {String? gasPrice}) {
  String data = makeMintTransactionData(from, tokenURI, cardId);
  final params = [
    {
      "from": from,
      "to": to,
      "data": data,
      "gasPrice": gasPrice ?? dotenv.get('DEFAULT_GAS_PRICE'),
      "gas": "0x30D40",
    },
  ];
  return params;
}

String makeBurnTransactionData(Uint8List cardId) {
  var burnFunctionSignature = '42966c68';
  var tokenIdHex = uint8ListTo32ByteHex(cardId);
  var burnTransactionData = "0x" + burnFunctionSignature + tokenIdHex;
  return burnTransactionData;
}

dynamic makeBurnParams(String? from, String to, Uint8List cardId,
    {String? gasPrice}) {
  String data = makeBurnTransactionData(cardId);
  final params = [
    {
      "from": from,
      "to": to,
      "data": data,
      "gasPrice": gasPrice ?? dotenv.get('DEFAULT_GAS_PRICE'),
      "gas": "0x30D40",
    },
  ];
  return params;
}

dynamic makeWatchAssetParams(String imageUri) {
  final params = [
    {
      "type": "ERC721",
      "options": {
        "address": dotenv.get("CONTRACT_ADDRESS"),
        "symbol": "OC",
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
