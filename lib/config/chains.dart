import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/config/chains.dart';

final polygonMumbaiTestnet = BlockchainConfig(
    networkName: "Polygon Mumbai Testnet",
    rpcUrl:
        "https://polygon-mumbai.infura.io/v3/b5b3b9c6bd56483c9203c06f9b0eb0f4",
    registryContract: "0xE587fb76509550a72Eb120b941F9235488aB6AEe",
    openseaUrl: "https://testnets.opensea.io/assets/mumbai",
    raribleUrl: "https://testnet.rarible.com/token/polygon",
    blockchainExplorerUrl: "https://mumbai.polygonscan.com/token",
    forwarderContract: "0x85256E65e6644eAC989154D4aaAa1bF06bD10E7f");
final polygonMainnet = BlockchainConfig(
    networkName: "Polygon Mainnet",
    rpcUrl:
        "https://polygon-mainnet.infura.io/v3/b5b3b9c6bd56483c9203c06f9b0eb0f4",
    registryContract: "0x4dD835afC9E02382e98700eC2fa5317aeE1f321d",
    openseaUrl: "https://opensea.io/assets/matic",
    raribleUrl: "https://rarible.com/token/polygon",
    blockchainExplorerUrl: "https://polygonscan.com/token",
    forwarderContract: "0x2De25940Adef17B4abF894c87CCd3Be893850668");

final ethereumMainnet = BlockchainConfig(
    networkName: "Ethereum Mainnet",
    rpcUrl: "https://mainnet.infura.io/v3/b5b3b9c6bd56483c9203c06f9b0eb0f4",
    registryContract: "0x8Dcc2016E0dEe536D238562dC2a46c8EEf2aac86",
    openseaUrl: "https://opensea.io/assets",
    raribleUrl: "https://rarible.com/token",
    blockchainExplorerUrl: "https://etherscan.com/token");

final Map<int, BlockchainConfig> chainConfig = {
  1: ethereumMainnet,
  137: polygonMainnet,
  80001: polygonMumbaiTestnet,
};
