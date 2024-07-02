import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/domain/blockchain_token.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:web3dart/web3dart.dart';

final polygonMainnet = BlockchainConfig(
    networkName: "Polygon Mainnet",
    nativeTokenSymbol: "MATIC",
    rpcUrl:
        "https://polygon-mainnet.g.alchemy.com/v2/${dotenv.env['ALCHEMY_API_KEY_POLYGON']}",
    registryContract: "0x4dD835afC9E02382e98700eC2fa5317aeE1f321d",
    controllerContract: "0x37068431C47950c4e857A850DBb8641E966Ca3D9",
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
        "https://eth-mainnet.g.alchemy.com/v2/${dotenv.env['ALCHEMY_API_KEY_ETH']}",
    registryContract: "0x8Dcc2016E0dEe536D238562dC2a46c8EEf2aac86",
    controllerContract: "",
    openseaUrl: "https://opensea.io/assets",
    raribleUrl: "https://rarible.com/token",
    raribleEnum: "ETHEREUM",
    alchemyBaseUrl: "https://eth-mainnet.g.alchemy.com/",
    blockchainExplorerUrl: "https://etherscan.com/token");

final sepoliaTestnet = BlockchainConfig(
  networkName: "Sepolia Testnet",
  nativeTokenSymbol: "ETH",
  rpcUrl:
      "https://eth-sepolia.g.alchemy.com/v2/${dotenv.env['ALCHEMY_API_KEY_SEPOLIA']}",
  registryContract: "0x8Dcc2016E0dEe536D238562dC2a46c8EEf2aac86",
  controllerContract: "0x4dD835afC9E02382e98700eC2fa5317aeE1f321d",
  forwarderContract: "0x4e63de97Cd856b9D835dB1656948E5227622F829",
  openseaUrl: "https://opensea.io/assets",
  raribleUrl: "https://testnet.rarible.com/token",
  raribleEnum: "ETHEREUM",
  alchemyBaseUrl: "https://eth-sepolia.g.alchemy.com/",
  blockchainExplorerUrl: "https://sepolia.etherscan.io/token",
  internal: true,
);

final Map<int, BlockchainConfig> _chainConfig = {
  1: ethereumMainnet,
  137: polygonMainnet,
  11155111: sepoliaTestnet,
};

Map<int, BlockchainConfig> get chainConfig {
  final Map<int, BlockchainConfig> configs = {};

  for (final chain in _chainConfig.entries) {
    if (chain.value.internal && dotenv.get("IS_INTERNAL") != "true") {
      continue;
    }
    configs[chain.key] = chain.value;
  }

  return configs;
}

final Map<int, List<BlockchainToken>> chainTokenConfigs = {
  1: [
    // BlockchainToken(
    //   symbol: "USDC",
    //   abiAssetPath: "assets/contracts/erc20.abi.json",
    //   contractAddress: EthereumAddress.fromHex(
    //     "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
    //   ),
    //   iconPath: "assets/images/common/usdc_icon.png",
    //   decimals: 6,
    // ),
    // BlockchainToken(
    //   symbol: "USDT",
    //   abiAssetPath: "assets/contracts/erc20.abi.json",
    //   contractAddress: EthereumAddress.fromHex(
    //     "0xdAC17F958D2ee523a2206206994597C13D831ec7",
    //   ),
    //   iconPath: "assets/images/common/usdt_icon.png",
    //   decimals: 6,
    // ),
  ],
  137: [
    BlockchainToken(
      symbol: "USDC",
      abiAssetPath: "assets/contracts/erc20.abi.json",
      contractAddress: EthereumAddress.fromHex(
        "0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359",
      ),
      iconPath: "assets/images/common/usdc_icon.png",
      decimals: 6,
    ),
    // BlockchainToken(
    //   symbol: "AVAX",
    //   abiAssetPath: "assets/contracts/erc20.abi.json",
    //   contractAddress: EthereumAddress.fromHex(
    //     "0x2C89bbc92BD86F8075d1DEcc58C7F4E0107f286b",
    //   ),
    //   iconPath: "assets/images/common/usdc_icon.png",
    //   decimals: 18,
    // ),
    // BlockchainToken(
    //   symbol: "USDT",
    //   abiAssetPath: "assets/contracts/erc20.abi.json",
    //   contractAddress: EthereumAddress.fromHex(
    //     "0xc2132D05D31c914a87C6611C10748AEb04B58e8F",
    //   ),
    //   iconPath: "assets/images/common/usdt_icon.png",
    //   decimals: 6,
    // ),
  ],
  11155111: [
    BlockchainToken(
      symbol: "USDC",
      abiAssetPath: "assets/contracts/erc20.abi.json",
      contractAddress: EthereumAddress.fromHex(
        "0x08D324a0f98D65A2bba83C9b62a2D12f59e59D91",
      ),
      iconPath: "assets/images/common/usdc_icon.png",
      decimals: 18,
    ),
  ],
};
