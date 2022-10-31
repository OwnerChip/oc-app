import 'package:flutter/foundation.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';

class ScanningScreenArguments {
  final String nextRoute;
  final String scanningTitle;
  ScanningScreenArguments(this.nextRoute, this.scanningTitle);
}

class UserScanResultsScreenArguments {
  final String nftOwner;
  final bool chipIsInitialized;
  final dynamic tokenId;
  final String chipWalletAddress;

  UserScanResultsScreenArguments(this.nftOwner, this.chipIsInitialized,
      this.tokenId, this.chipWalletAddress);
}

class ChipAlreadyInitializedScreenArguments {
  final WalletConnect? connector;
  final Uint8List tokenId;
  final String chipWalletAddress;

  ChipAlreadyInitializedScreenArguments(
      this.connector, this.tokenId, this.chipWalletAddress);
}

class ChipInitializedArguments {
  final WalletConnect? connector;
  final Uint8List tokenId;
  final String chipWalletAddress;

  ChipInitializedArguments(
      this.connector, this.tokenId, this.chipWalletAddress);
}

class NFTDetailsScreenArguments {
  final WalletConnect? connector;
  final Function? loginWithMetaMask;
  final BigInt? tokenId;
  final String? chipWalletAddress;

  NFTDetailsScreenArguments(this.connector, this.loginWithMetaMask,
      this.tokenId, this.chipWalletAddress);
}
