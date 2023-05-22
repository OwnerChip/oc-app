import 'package:web3dart/web3dart.dart';
import 'package:flutter/services.dart';
import 'package:web3dart/crypto.dart';

class Collection {
  final EthereumAddress id;
  final String name;
  final String? symbol;
  final int? chainId;
  bool? hasMinterRole;

  Collection(this.id, this.name,
      {this.symbol, this.chainId, this.hasMinterRole});
}

class BlockchainCollectionList {
  final Map<int, List<Collection>> collections;
  bool? hasAnyMinterRole;

  BlockchainCollectionList(this.collections, {this.hasAnyMinterRole});
}

class BlockchainConfig {
  final String networkName;
  final String rpcUrl;
  final String registryContract;
  final String openseaUrl;
  final String raribleUrl;
  final String blockchainExplorerUrl;
  final String? forwarderContract;

  BlockchainConfig(
      {required this.networkName,
      required this.rpcUrl,
      required this.registryContract,
      required this.openseaUrl,
      required this.raribleUrl,
      required this.blockchainExplorerUrl,
      this.forwarderContract});
}

class TokenInfoObject {
  final int chainId;
  final EthereumAddress collectionId;
  final BigInt tokenId;

  TokenInfoObject(this.chainId, this.collectionId, this.tokenId);
}

class ChipInfoModel {
  ChipInfoModel(
      {required this.chipEthereumAddress,
      required this.tokenId,
      this.chipIsInitialized = false});
  EthereumAddress chipEthereumAddress;
  BigInt tokenId;
  bool chipIsInitialized;
}

class SignatureData {
  Uint8List hashedMsg;
  MsgSignature signature;

  SignatureData({required this.hashedMsg, required this.signature});
}
