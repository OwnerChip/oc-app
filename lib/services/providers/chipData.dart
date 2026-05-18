import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class SignatureDataNotifier extends Notifier<SignatureData> {
  @override
  SignatureData build() {
    ref.keepAlive();
    return SignatureData(
      hashedMsg: Uint8List(0),
      signature: MsgSignature(BigInt.from(0), BigInt.from(0), 0),
      tokenId: BigInt.from(0),
    );
  }

  void setSignatureData(SignatureData signatureData) {
    state.hashedMsg = signatureData.hashedMsg;
    state.signature = signatureData.signature;
    state.tokenId = signatureData.tokenId;
    state.hasBeenUsedInSmartContract = false;
  }

  void updateHasBeenUsedInSmartContract(bool hasBeenUsedInSmartContract) {
    state.hasBeenUsedInSmartContract = hasBeenUsedInSmartContract;
  }
}

final chipSignatureDataProvider =
    NotifierProvider<SignatureDataNotifier, SignatureData>(
        SignatureDataNotifier.new);

class ChipInfoNotifier extends Notifier<ChipInfoModel> {
  @override
  ChipInfoModel build() {
    ref.keepAlive();
    return ChipInfoModel(
      chipEthereumAddress: zeroAddress,
      tokenId: BigInt.from(0),
      firstSlotKey: zeroAddress,
    );
  }

  void setTokenId(BigInt tokenId) {
    state.tokenId = tokenId;
  }

  void setChipEthereumAddress(EthereumAddress chipEthereumAddress) {
    state.chipEthereumAddress = chipEthereumAddress;
  }

  void setChipToInitialized() {
    state.chipIsInitialized = true;
  }

  void setFirstSlotKey(EthereumAddress? firstSlotKey) {
    state.firstSlotKey = firstSlotKey ?? zeroAddress;
  }
}

final chipInfoProvider =
    NotifierProvider<ChipInfoNotifier, ChipInfoModel>(ChipInfoNotifier.new);
