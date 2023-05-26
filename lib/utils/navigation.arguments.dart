import 'package:flutter/foundation.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class ScanningScreenArguments {
  final String nextRoute;

  ScanningScreenArguments(this.nextRoute);
}

class MetadataInputScreenArguments {
  final int randomMsg;
  final int chainId;
  final EthereumAddress collectionId;

  MetadataInputScreenArguments(this.randomMsg, this.chainId, this.collectionId);
}

class ChipAlreadyInitializedScreenArguments {
  final Uint8List hashedMsg;
  final MsgSignature signature;

  ChipAlreadyInitializedScreenArguments(this.hashedMsg, this.signature);
}
