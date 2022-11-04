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
  final BigInt tokenId;
  final String chipWalletAddress;

  UserScanResultsScreenArguments(this.nftOwner, this.chipIsInitialized,
      this.tokenId, this.chipWalletAddress);
}

class ChipAlreadyInitializedScreenArguments {
  final Uint8List tokenId;
  final String chipWalletAddress;

  ChipAlreadyInitializedScreenArguments(this.tokenId, this.chipWalletAddress);
}

class ChipInitializedArguments {
  final Uint8List tokenId;
  final String chipWalletAddress;

  ChipInitializedArguments(this.tokenId, this.chipWalletAddress);
}

class NFTDetailsScreenArguments {
  final BigInt tokenId;
  final String chipWalletAddress;

  NFTDetailsScreenArguments(this.tokenId, this.chipWalletAddress);
}
