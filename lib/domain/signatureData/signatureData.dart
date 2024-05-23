import 'dart:typed_data';

import 'package:web3dart/crypto.dart';

class SignatureData {
  Uint8List hashedMsg;
  MsgSignature signature;
  bool hasBeenUsedInSmartContract;

  SignatureData(
      {required this.hashedMsg,
        required this.signature,
        this.hasBeenUsedInSmartContract = false});
}
