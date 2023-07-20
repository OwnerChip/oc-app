import 'package:flutter/foundation.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class ScanningScreenArguments {
  final String nextRoute;

  ScanningScreenArguments(this.nextRoute);
}

class MetadataInputScreenArguments {
  final String sessionId;
  final int chainId;
  final EthereumAddress collectionId;

  MetadataInputScreenArguments(this.sessionId, this.chainId, this.collectionId);
}

class UserScanResultsScreenArguments {
  final String sessionId;

  UserScanResultsScreenArguments(this.sessionId);
}
