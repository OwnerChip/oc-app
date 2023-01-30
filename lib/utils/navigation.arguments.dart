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
  final BigInt tokenId;
  final String chipWalletAddress;

  UserScanResultsScreenArguments(this.nftOwner, this.chipIsInitialized,
      this.tokenId, this.chipWalletAddress);
}

class ChipAlreadyInitializedScreenArguments {
  final BigInt tokenId;
  final String chipEthereumAddress;
  final Uint8List hashedMsg;
  final MsgSignature signature;

  ChipAlreadyInitializedScreenArguments(
      this.tokenId, this.chipEthereumAddress, this.hashedMsg, this.signature);
}

class MetadataScreenArguments {
  final BigInt tokenId;
  final String chipWalletAddress;
  final Uint8List hashedMsg;
  final MsgSignature signature;

  MetadataScreenArguments(
      this.tokenId, this.chipWalletAddress, this.hashedMsg, this.signature);
}

class NFTDetailsScreenArguments {
  final BigInt tokenId;
  final String chipWalletAddress;

  NFTDetailsScreenArguments(this.tokenId, this.chipWalletAddress);
}
