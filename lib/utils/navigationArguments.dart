import 'package:web3dart/web3dart.dart';

import '../domain/attachmentType/attachmentType.dart';

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
