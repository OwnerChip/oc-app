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

  TokenInfoObject(this.rpcUrl, this.collectionId, this.tokenId);
}
