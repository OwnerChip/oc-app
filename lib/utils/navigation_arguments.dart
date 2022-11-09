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
  final Uint8List tokenIdHash;
  final Uint8List r;
  final Uint8List s;
  final Uint8List v;

  ChipAlreadyInitializedScreenArguments(this.tokenId, this.chipWalletAddress,
      this.tokenIdHash, this.r, this.s, this.v);
}

class ChipInitializedArguments {
  final Uint8List tokenId;
  final String chipWalletAddress;
  final Uint8List tokenIdHash;
  final Uint8List r;
  final Uint8List s;
  final Uint8List v;

  ChipInitializedArguments(this.tokenId, this.chipWalletAddress,
      this.tokenIdHash, this.r, this.s, this.v);
}

class NFTDetailsScreenArguments {
  final BigInt tokenId;
  final String chipWalletAddress;

  NFTDetailsScreenArguments(this.tokenId, this.chipWalletAddress);
}
