import 'package:flutter/foundation.dart';
import 'package:web3dart/crypto.dart';

class ScanningScreenArguments {
  final String nextRoute;
  ScanningScreenArguments(this.nextRoute);
}

class MetadataInputScreenArguments {
  final int randomMsg;
  MetadataInputScreenArguments(this.randomMsg);
}

class ChipAlreadyInitializedScreenArguments {
  final Uint8List hashedMsg;
  final MsgSignature signature;

  ChipAlreadyInitializedScreenArguments(this.hashedMsg, this.signature);
}
