import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:ownerchip_whitelabel/utils/nfc.commands.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:web3dart/crypto.dart';
import 'package:ownerchip_whitelabel/widgets/ui/returnSnackBarWidget.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:nfc_manager/platform_tags.dart';
import 'package:web3dart/web3dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/services/backend.services.dart';

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

Uint8List makeWriteNdefUrl(EthereumAddress chipEthereumAddressHex) {
  String url = getNdefUrl() + chipEthereumAddressHex.toString();

  // byte content
  Uint8List typeName = Uint8List.fromList([0x55]);
  Uint8List httpsPrefix = Uint8List.fromList([0x04]);
  Uint8List urlBytes = Uint8List.fromList(url.codeUnits);
  Uint8List urlPayload =
      Uint8List.fromList([...typeName, ...httpsPrefix, ...urlBytes]);

  Uint8List res = Uint8List.fromList([
    0,
    0xD6,
    0,
    0,
    urlPayload.length + 5,
    0,
    urlPayload.length + 3,
    0xD1,
    0x01,
    urlPayload.length - 1,
    ...urlPayload
  ]);
  print(res);
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
Future<List<dynamic>> initializeChip(
    NFCPlatform nfc, bool initializeNdef, int randomNumber) async {
  bool empty = false;
  //empty UintList
  await nfc.sendCommand(SELECT_APP);

  Uint8List chipPubKey = await getFirstKey(nfc);

  if (chipPubKey.isEmpty) {
    empty = true;
    chipPubKey = await generatePubAddress(nfc);
  }
  //check if response from get key is does NOT have success code 90 00 in hex --> 144 0 in decimal
  Uint8List chipEthereumAddress = publicKeyToAddress(chipPubKey);

  EthereumAddress chipEthereumAddressHex =
      EthereumAddress.fromHex("0x${bytesToHex(chipEthereumAddress)}");
  BigInt chipTokenId = bytesToUnsignedInt(chipEthereumAddress);
// initialize NDEF tag if empty AND NDEF should be initialized (aka, user is not just scanning but initializing a chip)
  if (/*empty &&*/ initializeNdef) {
    try {
      String url = getNdefUrl() + chipEthereumAddressHex.toString();
      await initializeNdefTag(nfc, chipEthereumAddressHex, randomNumber);
      sendAnalyticsTrace("$randomNumber", url, "INITIALIZE_NDEF_SUCCESS",
          tags: {"chipWallet": chipEthereumAddressHex.toString()});
    } catch (e) {
      sendAnalyticsTrace("$randomNumber", "", "INITIALIZE_NDEF_ERROR",
          tags: {"chipWallet": chipEthereumAddress.toString()});
      rethrow;
    }
  }

  return [chipEthereumAddressHex, chipTokenId, empty];
}

// initialize NDEF tag
Future<void> initializeNdefTag(NFCPlatform nfc,
    EthereumAddress chipEthereumAddressHex, int randomNumber) async {
  //select Applet
  var selectAppletRes = await nfc.sendCommand(SELECT_NDEF_APP);
  int selectAppletResCode1 = selectAppletRes[1];
  int selectAppletResCode2 = selectAppletRes[2];
  if (!(selectAppletResCode1 == 144 && selectAppletResCode2 == 00)) {
    if (selectAppletResCode1 == 106 && selectAppletResCode2 == 130) {
      // do NOTHING, but report analytics
      sendAnalyticsTrace(
          "$randomNumber",
          "${selectAppletResCode1.toRadixString(16)} ${selectAppletResCode2.toRadixString(16)}",
          "INITIALIZE_NDEF_NO_APPLET",
          tags: {"chipWallet": chipEthereumAddressHex.toString()});
      print("---- No NDEF applet installed! ----");
    } else {
      throw Exception(
          "Error while selecting NDEF applet. ERROR CODE: ${selectAppletResCode1.toRadixString(16)} ${selectAppletResCode2.toRadixString(16)}");
    }
  } else {
    print("---- ... initializing NDEF ----");

    //select NDEF file
    var selectNdefFileRes = await nfc.sendCommand(SELECT_NDEF_FILE);
    int selectNdefFileResCode1 = selectNdefFileRes[1];
    int selectNdefFileResCode2 = selectNdefFileRes[2];
    if (!(selectNdefFileResCode1 == 144 && selectNdefFileResCode2 == 00)) {
      throw Exception("Error while selecting NDEF file");
    }

    //write NDEF message
    Uint8List ndefUrlMsg = makeWriteNdefUrl(chipEthereumAddressHex);
    var writeNdefMessageRes = await nfc.sendCommand(ndefUrlMsg);
    int writeNdefMessageResCode1 = writeNdefMessageRes[1];
    int writeNdefMessageResCode2 = writeNdefMessageRes[2];
    if (!(writeNdefMessageResCode1 == 144 && writeNdefMessageResCode2 == 0)) {
      if (writeNdefMessageResCode1 == 105 && writeNdefMessageResCode2 == 133) {
        // do NOTHING, but report analytics
        sendAnalyticsTrace(
            "$randomNumber",
            "${selectAppletResCode1.toRadixString(16)} ${selectAppletResCode2.toRadixString(16)}",
            "INITIALIZE_NDEF_WRONG_STATE",
            tags: {"chipWallet": chipEthereumAddressHex.toString()});
        print(
            "---- NDEF is locked or NFC chip is not in correct state to write ----");
      } else {
        throw Exception(
            "Error while writing NDEF Url. ERROR CODE: ${selectAppletResCode1.toRadixString(16)} ${selectAppletResCode2.toRadixString(16)}");
      }
    }

    // lock NDEF file if app is not internal test version
    else if (dotenv.get('IS_INTERNAL') != 'true') {
      var lockNdefFileRes = await nfc.sendCommand(LOCK_NDEF_FILE);
      int lockNdefFileResCode1 = lockNdefFileRes[1];
      int lockNdefFileResCode2 = lockNdefFileRes[2];
      if (!(lockNdefFileResCode1 == 144 && lockNdefFileResCode2 == 00)) {
        throw Exception(
            "Error while locking NDEF. ERROR CODE: ${lockNdefFileResCode1.toRadixString(16)} ${lockNdefFileResCode2.toRadixString(16)}");
      }
    }
  }
}

Future<void> nfcPlatformCheck(
    BuildContext context, int caseId, NFCPlatform nfc) async {
  // null comparison below is NOT unnecessary!
  // ignore: unnecessary_null_comparison
  if (nfc == null) {
    NfcManager.instance.stopSession();
    ScaffoldMessenger.of(context).showSnackBar(
      returnSnackBarWidget(
          context.loc.errorHeadingSnackBar, context.loc.noNfc, 'error'),
    );
    sendAnalyticsTrace("$caseId", "", "SCAN_NFC_TYPE_NOT_SUPPORTED");
    //delay for 1 second
    await Future.delayed(Duration(seconds: 1));
    Navigator.pop(context);
    throw Exception('Tag is not ISO-DEP.');
  }
}
