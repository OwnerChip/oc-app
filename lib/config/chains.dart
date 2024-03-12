import 'package:ownerchip_whitelabel/domain/classDefinition.dart';

final polygonMumbaiTestnet = BlockchainConfig(
  networkName: "Polygon Mumbai Testnet",
  nativeTokenSymbol: "MATIC",
  rpcUrl:
      "https://polygon-mumbai.infura.io/v3/b5b3b9c6bd56483c9203c06f9b0eb0f4",
  registryContract: "0xE587fb76509550a72Eb120b941F9235488aB6AEe",
  controllerContract: "0x99a0EEBe6D5Abd437485B2c61522A0E5770fc681",
  openseaUrl: "https://testnets.opensea.io/assets/mumbai",
  raribleUrl: "https://testnet.rarible.com/token/polygon",
  raribleEnum: "POLYGON",
  blockchainExplorerUrl: "https://mumbai.polygonscan.com/token",
  alchemyBaseUrl: "https://polygon-mumbai.g.alchemy.com/",
  forwarderContract: "0xE3116Ba52ba63573ecB5964187A711ef7eF74107",
);

final polygonMainnet = BlockchainConfig(
    networkName: "Polygon Mainnet",
    nativeTokenSymbol: "MATIC",
    rpcUrl:
        "https://polygon-mainnet.infura.io/v3/b5b3b9c6bd56483c9203c06f9b0eb0f4",
    registryContract: "0x4dD835afC9E02382e98700eC2fa5317aeE1f321d",
    controllerContract: "0x7F15F01af90Fd8c1AA32264f44DB02E6bEd259aF",
    openseaUrl: "https://opensea.io/assets/matic",
    raribleUrl: "https://rarible.com/token/polygon",
    raribleEnum: "POLYGON",
    blockchainExplorerUrl: "https://polygonscan.com/token",
    alchemyBaseUrl: "https://polygon-mainnet.g.alchemy.com/",
    forwarderContract: "0x65CDf66C6FDDCD0a43042F237Aa871414b724f4d");

final ethereumMainnet = BlockchainConfig(
    networkName: "Ethereum Mainnet",
    nativeTokenSymbol: "ETH",
    rpcUrl: "https://mainnet.infura.io/v3/b5b3b9c6bd56483c9203c06f9b0eb0f4",
    registryContract: "0x8Dcc2016E0dEe536D238562dC2a46c8EEf2aac86",
    controllerContract: "",
    openseaUrl: "https://opensea.io/assets",
    raribleUrl: "https://rarible.com/token",
    raribleEnum: "ETHEREUM",
    alchemyBaseUrl: "https://eth-mainnet.g.alchemy.com/",
    blockchainExplorerUrl: "https://etherscan.com/token");

final Map<int, BlockchainConfig> chainConfig = {
  1: ethereumMainnet,
  137: polygonMainnet,
  80001: polygonMumbaiTestnet,
};
