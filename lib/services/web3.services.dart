import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web3dart/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';

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

Future<BigInt> estimateGas(Uint8List txData, String fromAddress) async {
  final web3Client = getWeb3Client();
  BigInt result = await web3Client.estimateGas(
      sender: EthereumAddress.fromHex(fromAddress),
      to: EthereumAddress.fromHex(dotenv.env['CONTRACT_ADDRESS']!),
      data: txData);
  return result;
}

Future<BigInt> estimateGasPrice() async {
  final web3Client = getWeb3Client();
  EtherAmount gasPrice = await web3Client.getGasPrice();
  return gasPrice.getInWei;
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
    return false;
  }
}

// contract version 2
Future<List<dynamic>> makeSignedMintParams(String? from, Uint8List tokenIdHash,
    String tokenURI, MsgSignature signature,
    {String? gasPrice}) async {
  String data = "0xcb5a7173" +
      uint8ListTo32ByteHex(tokenIdHash) + //bytes32
      "a0".padLeft(64, '0') + //string prefix
      signature.r.toRadixString(16).padLeft(64, '0') + //bytes32
      signature.s.toRadixString(16).padLeft(64, '0') + //bytes32
      signature.v.toRadixString(16).padLeft(64, '0') + //uint8
      (tokenURI.length).toRadixString(16).padLeft(64, '0') +
      stringToHex(tokenURI); //string;

  String gasAmount = "0x249F0"; // fallback: 150000 gas
  try {
    BigInt gasAmountEst = await estimateGas(hexToBytes(data), from!);
    gasAmount = "0x${gasAmountEst.toRadixString(16)}";
    print("ESTIMATED GAS AMOUNT: $gasAmount");
  } catch (e) {
    print("ERROR estimating gas amount: $e");
  }

  if (gasPrice == null) {
    try {
      BigInt estimatedGasPrice = await estimateGasPrice();
      gasPrice = "0x${estimatedGasPrice.toRadixString(16)}";
      print("ESTIMATED GAS PRICE: $gasPrice");
    } catch (e) {
      print("ERROR estimating gas price: $e");
      gasPrice = dotenv.get('DEFAULT_GAS_PRICE'); // fallback
    }
  }

  final params = [
    {
      "from": from,
      "to": dotenv.env['CONTRACT_ADDRESS'],
      "data": data,
      "gasPrice": gasPrice,
      "gas": gasAmount
    },
  ];
  return params;
}

// contract version 2
Future<List<dynamic>> makeSignedBurnParams(
    String? from, Uint8List tokenIdHash, MsgSignature signature,
    {String? gasPrice}) async {
  String data = "0x469fd767" +
      uint8ListTo32ByteHex(tokenIdHash) +
      signature.r.toRadixString(16).padLeft(64, '0') +
      signature.s.toRadixString(16).padLeft(64, '0') +
      signature.v.toRadixString(16).padLeft(64, '0');

  String gasAmount = "0xC350"; // fallback: 50000 gas
  try {
    BigInt gasAmountEst = await estimateGas(hexToBytes(data), from!);
    gasAmount = "0x${gasAmountEst.toRadixString(16)}";
    print("ESTIMATED GAS AMOUNT: $gasAmount");
  } catch (e) {
    print("ERROR estimating gas amount: $e");
  }

  if (gasPrice == null) {
    try {
      BigInt estimatedGasPrice = await estimateGasPrice();
      gasPrice = "0x${estimatedGasPrice.toRadixString(16)}";
      print("ESTIMATED GAS PRICE: $gasPrice");
    } catch (e) {
      print("ERROR estimating gas price: $e");
      gasPrice = dotenv.get('DEFAULT_GAS_PRICE'); // fallback
    }
  }

  final params = [
    {
      "from": from,
      "to": dotenv.env['CONTRACT_ADDRESS'],
      "data": data,
      "gasPrice": gasPrice,
      "gas": gasAmount
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
    return owner[0];
  } catch (e) {
    print('Error while fetching owner of tokenId $tokenId: $e');
    return e;
  }
}

Future<dynamic> getTokenUri(BigInt tokenId) async {
  try {
    var uri = await query("tokenURI", [tokenId]);
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
