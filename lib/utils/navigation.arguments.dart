import 'package:flutter/foundation.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:web3dart/crypto.dart';

class ScanningScreenArguments {
  final String nextRoute;
  ScanningScreenArguments(this.nextRoute);
}

class UserScanResultsScreenArguments {
  final String nftOwner;
  final bool chipIsInitialized;
  final String chipWalletAddress;

  UserScanResultsScreenArguments(
      this.nftOwner, this.chipIsInitialized, this.chipWalletAddress);
}

class ChipAlreadyInitializedScreenArguments {
  final String chipEthereumAddress;
  final Uint8List hashedMsg;
  final MsgSignature signature;

  ChipAlreadyInitializedScreenArguments(
      this.chipEthereumAddress, this.hashedMsg, this.signature);
}

class MetadataScreenArguments {
  final String chipWalletAddress;
  final Uint8List hashedMsg;
  final MsgSignature signature;

  MetadataScreenArguments(
      this.chipWalletAddress, this.hashedMsg, this.signature);
}

class NFTDetailsScreenArguments {
  final String chipWalletAddress;

  NFTDetailsScreenArguments(this.chipWalletAddress);
}
