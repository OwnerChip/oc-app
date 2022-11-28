import 'package:flutter/foundation.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:web3dart/crypto.dart';

class ScanningScreenArguments {
  final String nextRoute;
  final String scanningTitle;
  ScanningScreenArguments(this.nextRoute, this.scanningTitle);
}

class UserScanResultsScreenArguments {
  final String nftOwner;
  final bool chipIsInitialized;
  final Uint8List tokenId;
  final String chipWalletAddress;

  UserScanResultsScreenArguments(this.nftOwner, this.chipIsInitialized,
      this.tokenId, this.chipWalletAddress);
}

class ChipAlreadyInitializedScreenArguments {
  final Uint8List tokenId;
  final String chipWalletAddress;
  final Uint8List hashedMsg;
  final MsgSignature signature;

  ChipAlreadyInitializedScreenArguments(
      this.tokenId, this.chipWalletAddress, this.hashedMsg, this.signature);
}

class ChipInitializedArguments {
  final Uint8List tokenId;
  final String chipWalletAddress;
  final Uint8List hashedMsg;
  final MsgSignature signature;

  ChipInitializedArguments(
      this.tokenId, this.chipWalletAddress, this.hashedMsg, this.signature);
}

class NFTDetailsScreenArguments {
  final Function? loginWithMetaMask;
  final Uint8List tokenId;
  final String chipWalletAddress;
  final String? localImagePath;

  NFTDetailsScreenArguments(this.loginWithMetaMask, this.tokenId,
      this.chipWalletAddress, this.localImagePath);
}
