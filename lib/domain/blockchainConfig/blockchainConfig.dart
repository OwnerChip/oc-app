class BlockchainConfig {
  final String networkName;
  final String nativeTokenSymbol;
  final String rpcUrl;
  final String registryContract;
  final String controllerContract;
  final String openseaUrl;
  final String raribleUrl;
  final String raribleEnum;
  final String blockchainExplorerUrl;
  final String alchemyBaseUrl;
  final String? forwarderContract;

  BlockchainConfig(
      {required this.networkName,
      required this.nativeTokenSymbol,
      required this.rpcUrl,
      required this.registryContract,
      required this.controllerContract,
      required this.openseaUrl,
      required this.raribleUrl,
      required this.raribleEnum,
      required this.blockchainExplorerUrl,
      required this.alchemyBaseUrl,
      this.forwarderContract});
}
