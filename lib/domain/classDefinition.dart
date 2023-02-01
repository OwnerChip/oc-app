import 'package:web3dart/web3dart.dart';

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
  final String rpcUrl;
  final String collectionId;
  final BigInt tokenId;
  EthereumAddress nftOwner;

  TokenInfoObject(this.rpcUrl, this.collectionId, this.tokenId, this.nftOwner);
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
