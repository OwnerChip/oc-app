import 'package:flutter/foundation.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import '../domain/classDefinition.dart';

class MetadataInputScreenArguments {
  final String sessionId;
  final int chainId;
  final EthereumAddress collectionId;

  MetadataInputScreenArguments(this.sessionId, this.chainId, this.collectionId);
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

class PinScreenArguments {
  final PinScreenActiveFeature activeFeature;
  final Function callback;

  PinScreenArguments({
    required this.activeFeature,
    required this.callback,
  });
}

enum PinScreenActiveFeature { setPin, verifyPinAuth, verifyPinTx }
