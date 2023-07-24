import 'package:flutter/foundation.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import '../domain/classDefinition.dart';

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

class AttachmentScreensArguments {
  final bool isEditMode;
  final AttachmentType type;
  final int? index;

  AttachmentScreensArguments(
    this.isEditMode,
    this.type, {
    this.index,
  });
}
