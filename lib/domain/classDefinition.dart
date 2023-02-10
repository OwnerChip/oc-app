import 'package:web3dart/web3dart.dart';
import 'package:flutter/services.dart';
import 'package:web3dart/crypto.dart';

class BlockchainConfig {
  final String networkName;
  final String rpcUrl;
  final String registryContract;
  final String openseaUrl;
  final String raribleUrl;
  final String blockchainExplorerUrl;

  BlockchainConfig(this.networkName, this.rpcUrl, this.registryContract,
      this.openseaUrl, this.raribleUrl, this.blockchainExplorerUrl);
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
