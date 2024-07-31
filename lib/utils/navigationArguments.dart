import 'package:flutter/foundation.dart';
import 'package:ownerchip_whitelabel/domain/creation/digitalTwinAttachment.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import '../domain/classDefinition.dart';

class MetadataInputScreenArguments {
  final String sessionId;
  final int chainId;
  final EthereumAddress collectionId;
  final EthereumAddress? voucherAddress;

  MetadataInputScreenArguments(this.sessionId, this.chainId, this.collectionId,
      {this.voucherAddress});
}

class AttachmentScreensArguments {
  final bool isEditMode;
  final AttachmentType type;
  final int? index;

  final DigitalTwinAttachment? twinAttachment;
  final String? metadataId;

  AttachmentScreensArguments(
    this.isEditMode,
    this.type, {
    this.index,
    this.twinAttachment,
    required this.metadataId,
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
