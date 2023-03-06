import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:ownerchip_whitelabel/utils/nfc.commands.dart';
import 'package:web3dart/crypto.dart';
import 'package:ownerchip_whitelabel/widgets/ui/returnSnackBarWidget.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:nfc_manager/platform_tags.dart';
import 'package:web3dart/web3dart.dart';

class NFCPlatform {
  var platform = defaultTargetPlatform;
  final NfcTag tag;
  // cannot assign type to nfc because type depends on platform
  // ignore: prefer_typing_uninitialized_variables
  late final nfc;
  NFCPlatform(this.tag) {
    if (Platform.isIOS) {
      nfc = Iso7816.from(tag);
    } else if (Platform.isAndroid) {
      nfc = IsoDep.from(tag);
    }
  }

  Future<List> sendCommand(Uint8List data) async {
    if (Platform.isIOS) {
      Iso7816ResponseApdu res = await nfc.sendCommandRaw(data);
      return [res.payload, res.statusWord1, res.statusWord2];
    } else if (Platform.isAndroid) {
      Uint8List res = await nfc.transceive(data: data);
      return [
        res.sublist(0, res.length - 2),
        res[res.length - 2],
        res[res.length - 1]
      ];
    }
    throw Exception("Unsupported platform");
  }
}

//****COMMANDS****

Uint8List makeGetKeyInfoCommand(hexKeyNumber) {
  return Uint8List.fromList([
    0x00,
    0x16,
    hexKeyNumber,
    0x00,
    0x00,
  ]);
}

Uint8List makeSignatureCommand(int hexKeyNumber, Uint8List dataToSign) {
  var bytes = BytesBuilder();
  Uint8List a = Uint8List.fromList([
    0x00,
    0x18,
    hexKeyNumber,
    0x00,
    0x20,
  ]);
  bytes.add(a);
  bytes.add(dataToSign);
  bytes.add(Uint8List.fromList([0x00]));
  Uint8List res = bytes.toBytes();
  return res;
}

//****NFC HELPERS****

Future<Uint8List> getFirstKey(NFCPlatform nfc) async {
  Uint8List getKeyInfo = makeGetKeyInfoCommand(0x01);
  var responseGetKeyInfo = await nfc.sendCommand(getKeyInfo);

  Uint8List getKeyInfoData = responseGetKeyInfo[0];
  int getKeyInfoResponseCode1 = responseGetKeyInfo[1];
  int getKeyInfoResponseCode2 = responseGetKeyInfo[2];

  //check if first key does not exist yet exist; [106, 136] is error code for key does not exist in decimal
  bool keyExists =
      !(getKeyInfoResponseCode1 == 106 && getKeyInfoResponseCode2 == 136);

  if (keyExists) {
    Uint8List chipPubKey = getPublicKeyFromChipResponse(getKeyInfoData);
    return chipPubKey;
  } else {
    return Uint8List(0);
  }
}

Future<Uint8List> generatePubAddress(NFCPlatform nfc) async {
  //create new key
  var responseGenerateKey = await nfc.sendCommand(GENERATE_KEY);
  //get first key info after generating new key
  Uint8List getKeyInfo = makeGetKeyInfoCommand(0x01);
  var responseGetKeyInfo = await nfc.sendCommand(getKeyInfo);
  Uint8List getKeyInfoData = responseGetKeyInfo[0];
  int getKeyInfoResponseCode1 = responseGetKeyInfo[1];
  int getKeyInfoResponseCode2 = responseGetKeyInfo[2];

  if (!(getKeyInfoResponseCode1 == 144 && getKeyInfoResponseCode2 == 00)) {
    throw Exception("Error while generating key");
  }
  Uint8List chipPubKey = getPublicKeyFromChipResponse(getKeyInfoData);

  return chipPubKey;
}

//check if first key already exists, if not, generate key. Return key info.
Future<List<dynamic>> initializeChip(NFCPlatform nfc) async {
  //empty UintList
  await nfc.sendCommand(SELECT_APP);

  Uint8List chipPubKey = await getFirstKey(nfc);

  if (chipPubKey.isEmpty) {
    chipPubKey = await generatePubAddress(nfc);
  }
  //check if response from get key is does NOT have success code 90 00 in hex --> 144 0 in decimal
  Uint8List chipEthereumAddress = publicKeyToAddress(chipPubKey);

  EthereumAddress chipEthereumAddressHex =
      EthereumAddress.fromHex("0x${bytesToHex(chipEthereumAddress)}");
  BigInt chipTokenId = bytesToUnsignedInt(chipEthereumAddress);

  return [chipEthereumAddressHex, chipTokenId];
}

Future<void> nfcPlatformCheck(BuildContext context, NFCPlatform nfc) async {
  // null comparison below is NOT unnecessary!
  // ignore: unnecessary_null_comparison
  if (nfc == null) {
    NfcManager.instance.stopSession();
    ScaffoldMessenger.of(context).showSnackBar(
      returnSnackBarWidget(
          context.loc.errorHeadingSnackBar, context.loc.noNfc, 'error'),
    );
    //delay for 1 second
    await Future.delayed(Duration(seconds: 1));
    Navigator.pop(context);
    throw Exception('Tag is not ISO-DEP.');
  }
}
