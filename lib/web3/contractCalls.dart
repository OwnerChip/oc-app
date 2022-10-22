import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import '../contracts/contract.g.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web3dart/crypto.dart';

import '../utils/utils.dart';

Future<dynamic> getTxnReceipt(String txnHash) async {
  const rpcUrl =
      'https://rpc-mumbai.maticvigil.com/v1/7d84e17ef96385b4619c230429095c5e5379f316';
  final client = Web3Client(rpcUrl, Client());

  try {
    var txnReceipt = await client.getTransactionReceipt(txnHash);
    while (txnReceipt == null) {
      txnReceipt = await client.getTransactionReceipt(txnHash);
    }
    return txnReceipt;
  } catch (e) {
    print('Error while fetching txn receipt: $e');
    return e;
  }
}

Future<dynamic> getOwner(BigInt tokenId) async {
  const rpcUrl =
      'https://rpc-mumbai.maticvigil.com/v1/7d84e17ef96385b4619c230429095c5e5379f316';
  final client = Web3Client(rpcUrl, Client());

  final contract = Contract(
    address: EthereumAddress.fromHex(
        '0xfC97db8f5F39FE3354427674ABfC219795eba782'), // smart contract address
    client: client,
  );

  try {
    var owner = await contract.ownerOf(tokenId);
    return owner.hex;
  } catch (e) {
    print('Error while fetching owner of tokenId $tokenId: $e');
    return e;
  }
}

Future<dynamic> mintToken(
    addressHexString, String tokenURI, BigInt tokenId) async {
  const rpcUrl =
      'https://rpc-mumbai.maticvigil.com/v1/7d84e17ef96385b4619c230429095c5e5379f316';
  final client = Web3Client(rpcUrl, Client());

  final credentials = EthPrivateKey.fromHex(
    '534a427b9822b4de82b59466b5ad49e3a89371ff5da4f65f640bdb051acaab0e', // private key that interacts with the contract
  );

  final contract = Contract(
    address: EthereumAddress.fromHex(
        '0xfC97db8f5F39FE3354427674ABfC219795eba782'), // smart contract address
    client: client,
  );

  EthereumAddress walletAddress = EthereumAddress.fromHex(addressHexString);

  try {
    var txnHash = await contract.mint(walletAddress, tokenURI, tokenId,
        credentials: credentials);
    var txnReceipt = await client.getTransactionReceipt(txnHash);
    while (txnReceipt == null) {
      txnReceipt = await client.getTransactionReceipt(txnHash);
    }
    return txnReceipt;
  } catch (e) {
    print('Error while minting token: ');
    print(e);
    return e;
  }
}

Future<dynamic> burnToken(BigInt tokenId) async {
  const rpcUrl =
      'https://rpc-mumbai.maticvigil.com/v1/7d84e17ef96385b4619c230429095c5e5379f316';
  final client = Web3Client(rpcUrl, Client());

  final credentials = EthPrivateKey.fromHex(
    '534a427b9822b4de82b59466b5ad49e3a89371ff5da4f65f640bdb051acaab0e', // private key that interacts with the contract
  );

  final contract = Contract(
    address: EthereumAddress.fromHex(
        '0xfC97db8f5F39FE3354427674ABfC219795eba782'), // smart contract address
    client: client,
  );

  try {
    var txnHash = await contract.burn(tokenId, credentials: credentials);
    var txnReceipt = await client.getTransactionReceipt(txnHash);
    while (txnReceipt == null) {
      txnReceipt = await client.getTransactionReceipt(txnHash);
    }
    return txnReceipt;
  } catch (e) {
    print('Error while burning token: ');
    print(e);
    return e;
  }
}
