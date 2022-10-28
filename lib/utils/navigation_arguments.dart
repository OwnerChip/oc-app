import 'package:flutter/foundation.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';

class ScanScreenArguments {
  final String nextRoute;
  ScanScreenArguments(this.nextRoute);
}

class GetResultArguments {
  final WalletConnect? connector;
  final Uint8List tokenId;

  GetResultArguments(this.connector, this.tokenId);
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
