import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/config/chains.dart';

final polygonMumbaiTestnet = BlockchainConfig(
    "Polygon Mumbai Testnet",
    "https://polygon-mumbai.infura.io/v3/b5b3b9c6bd56483c9203c06f9b0eb0f4",
    "0xE587fb76509550a72Eb120b941F9235488aB6AEe",
    "https://testnets.opensea.io/assets/mumbai",
    "https://testnet.rarible.com/token/polygon",
    "https://mumbai.polygonscan.com/token");
final polygonMainnet = BlockchainConfig(
    "Polygon Mainnet",
    "https://polygon-mainnet.infura.io/v3/b5b3b9c6bd56483c9203c06f9b0eb0f4",
    "0x4dD835afC9E02382e98700eC2fa5317aeE1f321d",
    "https://opensea.io/assets/matic",
    "https://rarible.com/token/polygon",
    "https://polygonscan.com/token");

final ethereumMainnet = BlockchainConfig(
    "Ethereum Mainnet",
    "https://mainnet.infura.io/v3/b5b3b9c6bd56483c9203c06f9b0eb0f4",
    "0x8Dcc2016E0dEe536D238562dC2a46c8EEf2aac86",
    "https://opensea.io/assets",
    "https://rarible.com/token",
    "https://etherscan.com/token");

final Map<int, BlockchainConfig> chainConfig = {
  1: ethereumMainnet,
  137: polygonMainnet,
  80001: polygonMumbaiTestnet,
};
