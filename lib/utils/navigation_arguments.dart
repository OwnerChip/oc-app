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
  final Uint8List cardId;
  final String chipWalletAddress;

  ChipAlreadyInitializedScreenArguments(this.cardId, this.chipWalletAddress);
}

class NFTDetailsScreenArguments {
  final Function? loginWithMetaMask;
  final BigInt? tokenId;
  final String chipWalletAddress;
  final String? localImagePath;

  NFTDetailsScreenArguments(this.loginWithMetaMask, this.tokenId,
      this.chipWalletAddress, this.localImagePath);
}
