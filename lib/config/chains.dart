import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';

final polygonMainnet = BlockchainConfig(
    networkName: "Polygon Mainnet",
    nativeTokenSymbol: "MATIC",
    rpcUrl:
        // "https://polygon-mainnet.infura.io/v3/b5b3b9c6bd56483c9203c06f9b0eb0f4",
        "https://polygon-mainnet.g.alchemy.com/v2/${dotenv.env['ALCHEMY_API_KEY_POLYGON']}",
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
    rpcUrl:
        // "https://mainnet.infura.io/v3/b5b3b9c6bd56483c9203c06f9b0eb0f4",
        "https://eth-mainnet.g.alchemy.com/v2/${dotenv.env['ALCHEMY_API_KEY_ETH']}",
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
};
