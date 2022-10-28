import 'package:flutter/foundation.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';

class ScanningScreenArguments {
  final String nextRoute;
  ScanningScreenArguments(this.nextRoute);
}

class UserScanResultsScreenArguments {
  final String nftOwner;
  final bool chipIsInitialized;

  UserScanResultsScreenArguments(this.nftOwner, this.chipIsInitialized);
}

class ChipAlreadyInitializedScreenArguments {
  final WalletConnect? connector;
  final BigInt? tokenId;

  ChipAlreadyInitializedScreenArguments(this.connector, this.tokenId);
}

class ChipInitializedArguments {
  final WalletConnect? connector;
  final Uint8List tokenId;

  ChipInitializedArguments(this.connector, this.tokenId);
}
