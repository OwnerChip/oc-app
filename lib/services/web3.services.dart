import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web3dart/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';

Web3Client getWeb3Client(String chainRpcUrl) {
  var client = Web3Client(chainRpcUrl, Client());
  return client;
}

Future<DeployedContract> getCollectionContract(String collectionId) async {
  String abi =
      await rootBundle.loadString("assets/contracts/collection.abi.json");
  DeployedContract contract = DeployedContract(
    ContractAbi.fromJson(abi, 'OwnerChipDemo'),
    EthereumAddress.fromHex(collectionId),
  );
  return contract;
}

Future<DeployedContract> getRegistryContract(
    String registryContractAddress) async {
  String abi =
      await rootBundle.loadString("assets/contracts/registry.abi.json");
  DeployedContract contract = DeployedContract(
    ContractAbi.fromJson(abi, 'OwnerChipRegistry'),
    EthereumAddress.fromHex(registryContractAddress),
  );
  return contract;
}

Future<List<dynamic>> queryRegistryContract(
    String chainRpcUrl,
    String registryContractAddress,
    String functionName,
    List<dynamic> args) async {
  DeployedContract contract =
      await getRegistryContract(registryContractAddress);
  ContractFunction function = contract.function(functionName);
  final web3Client = getWeb3Client(chainRpcUrl);
  List<dynamic> result = await web3Client.call(
      contract: contract, function: function, params: args);
  return result;
}

Future<List<dynamic>> queryCollectionContract(String chainRpcUrl,
    String collectionId, String functionName, List<dynamic> args) async {
  DeployedContract contract = await getCollectionContract(collectionId);
  ContractFunction function = contract.function(functionName);
  final web3Client = getWeb3Client(chainRpcUrl);
  List<dynamic> result = await web3Client.call(
      contract: contract, function: function, params: args);
  return result;
}

Future<BigInt> estimateGas(String chainRpcUrl, String contractAddress,
    Uint8List txData, String fromAddress) async {
  final web3Client = getWeb3Client(chainRpcUrl);
  BigInt result = await web3Client.estimateGas(
      sender: EthereumAddress.fromHex(fromAddress),
      to: EthereumAddress.fromHex(contractAddress),
      data: txData);
  return result;
}

Future<BigInt> estimateGasPrice(String chainRpcUrl) async {
  final web3Client = getWeb3Client(chainRpcUrl);
  EtherAmount gasPrice = await web3Client.getGasPrice();
  return gasPrice.getInWei;
}

// contract version 2
Future<bool> verifyTokenSigner(
    String chainRpcUrl,
    String collectionId,
    EthereumAddress chipWalletAddressHex,
    Uint8List tokenIdHash,
    MsgSignature signature) async {
  Uint8List r = bytesFromBigInt(signature.r);
  Uint8List s = bytesFromBigInt(signature.s);
  try {
    var result = await queryCollectionContract(chainRpcUrl, collectionId,
        "getSigner", [tokenIdHash, r, s, BigInt.from(signature.v)]);
    bool res = (chipWalletAddressHex ==
        EthereumAddress.fromHex(result[0].toString().toLowerCase()));
    return res;
  } catch (e) {
    return false;
  }
}

// contract version 2
Future<List<dynamic>> makeSignedMintParams(
    String chainRpcUrl,
    String collectionId,
    String? from,
    Uint8List tokenIdHash,
    String tokenURI,
    MsgSignature signature,
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
    BigInt gasAmountEst =
        await estimateGas(chainRpcUrl, collectionId, hexToBytes(data), from!);
    gasAmount = "0x${gasAmountEst.toRadixString(16)}";
    print("ESTIMATED GAS AMOUNT: $gasAmount");
  } catch (e) {
    print("ERROR estimating gas amount: $e");
  }

  if (gasPrice == null) {
    try {
      BigInt estimatedGasPrice = await estimateGasPrice(chainRpcUrl);
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
      "to": collectionId,
      "data": data,
      "gasPrice": gasPrice,
      "gas": gasAmount
    },
  ];
  return params;
}

// contract version 2
Future<List<dynamic>> makeSignedBurnParams(
    String chainRpcUrl,
    String collectionId,
    String? from,
    Uint8List tokenIdHash,
    MsgSignature signature,
    {String? gasPrice}) async {
  String data = "0x469fd767" +
      uint8ListTo32ByteHex(tokenIdHash) +
      signature.r.toRadixString(16).padLeft(64, '0') +
      signature.s.toRadixString(16).padLeft(64, '0') +
      signature.v.toRadixString(16).padLeft(64, '0');

  String gasAmount = "0xC350"; // fallback: 50000 gas
  try {
    BigInt gasAmountEst =
        await estimateGas(chainRpcUrl, collectionId, hexToBytes(data), from!);
    gasAmount = "0x${gasAmountEst.toRadixString(16)}";
    print("ESTIMATED GAS AMOUNT: $gasAmount");
  } catch (e) {
    print("ERROR estimating gas amount: $e");
  }

  if (gasPrice == null) {
    try {
      BigInt estimatedGasPrice = await estimateGasPrice(chainRpcUrl);
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
      "to": collectionId,
      "data": data,
      "gasPrice": gasPrice,
      "gas": gasAmount
    },
  ];
  return params;
}

Future<dynamic> getOwner(
    String chainRpcUrl, String collectionId, BigInt tokenId) async {
  try {
    var owner = await queryCollectionContract(
        chainRpcUrl, collectionId, "ownerOf", [tokenId]);
    return owner[0];
  } catch (e) {
    print('Error while fetching owner of tokenId $tokenId: $e');
    return e;
  }
}

Future<dynamic> getTokenUri(
    String chainRpcUrl, String collectionId, BigInt tokenId) async {
  try {
    var uri = await queryCollectionContract(
        chainRpcUrl, collectionId, "tokenURI", [tokenId]);
    return uri[0];
  } catch (e) {
    print('Error while fetching uri of tokenId $tokenId: $e');
    throw Exception('Error while fetching uri of tokenId $tokenId: $e');
  }
}

Future<EthereumAddress> getCollectionId(
    String chainRpcUrl, String registryAddress, BigInt tokenId) async {
  try {
    List collectionId = await queryRegistryContract(
        chainRpcUrl, registryAddress, "tokenRegistry", [tokenId]);
    return collectionId[0];
  } catch (e) {
    print('Error while fetching registry entry of tokenId $tokenId: $e');
    throw Exception(
        'Error while fetching registry entry of tokenId $tokenId: $e');
  }
}

Future<dynamic> getTxnReceipt(String chainRpcUrl, String txnHash) async {
  final web3Client = getWeb3Client(chainRpcUrl);

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
