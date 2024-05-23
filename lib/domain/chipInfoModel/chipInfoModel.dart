import 'package:web3dart/web3dart.dart';

class ChipInfoModel {
  ChipInfoModel(
      {required this.chipEthereumAddress,
      required this.tokenId,
      this.chipIsInitialized = false});

  EthereumAddress chipEthereumAddress;
  BigInt tokenId;
  bool chipIsInitialized;
}
