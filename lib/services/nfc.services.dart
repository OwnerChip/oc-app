import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:ownerchip_whitelabel/utils/nfc.commands.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:web3dart/crypto.dart';
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

  /// sends an APDU commands and returns the response List<Uint8List, int, int>
  Future<List<dynamic>> sendCommand(Uint8List data) async {
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

Uint8List setPinCommand(String pin) {
  final Uint8List cmd = Uint8List.fromList([
    0x00,
    0x40,
    0x00,
    0x00,
    pin.length, // Length of the PIN in bytes (between 4 and 62 bytes)
    ...pin.codeUnits,
    0x08 // Expected length of answer
  ]);
  return cmd;
}

Uint8List verifyPinCommand(String pin) {
  final Uint8List cmd = Uint8List.fromList([
    0x00,
    0x44,
    0x00,
    0x00,
    pin.length, // Length of the PIN in bytes (between 4 and 62 bytes)
    ...pin.codeUnits
  ]);
  return cmd;
}

Uint8List changePinCommand(String oldPin, String newPin) {
  final Uint8List cmd = Uint8List.fromList([
    0x00,
    0x42,
    0x00,
    0x00,
    oldPin.length + newPin.length + 2,
    oldPin.length,
    ...oldPin.codeUnits,
    newPin.length,
    ...newPin.codeUnits,
    0x08 // Expected length of answer
  ]);
  return cmd;
}

Uint8List unlockPinCommand(Uint8List puk) {
  final Uint8List cmd = Uint8List.fromList([
    0x00,
    0x46,
    0x00,
    0x00,
    0x08,
    ...puk,
  ]);
  return cmd;
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

Uint8List importKeyCommand(Uint8List seed) {
  final Uint8List cmd = Uint8List.fromList([
    0x00,
    0x20,
    0x00,
    0x00,
    0x10,
    ...seed,
  ]);
  return cmd;
}

Uint8List makeWriteNdefUrl(EthereumAddress chipEthereumAddressHex) {
  String url = getNdefUrl() +
      chipEthereumAddressHex.toString() +
      '?appId=' +
      dotenv.get('APP_ID');

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

Future<Uint8List> getFirstPubKey(NFCPlatform nfc) async {
  return await getPubKeyN(nfc, 0x01);
}

//write key to slot zero
Future<void> writeKeyToSlotZero(NFCPlatform nfc, Uint8List seed) async {
  Uint8List importKey = importKeyCommand(seed);
  var responseImportKey = await nfc.sendCommand(importKey);
  int responseCode1 = responseImportKey[1];
  int responseCode2 = responseImportKey[2];

  if (!(responseCode1 == 144 && responseCode2 == 00)) {
    throw Exception("Error while importing key");
  }
}

//getKeyN
Future<Uint8List> getPubKeyN(NFCPlatform nfc, int key) async {
  Uint8List getKeyInfo = makeGetKeyInfoCommand(key);
  var responseGetKeyInfo = await nfc.sendCommand(getKeyInfo);

  Uint8List getKeyInfoData = responseGetKeyInfo[0];
  int getKeyInfoResponseCode1 = responseGetKeyInfo[1];
  int getKeyInfoResponseCode2 = responseGetKeyInfo[2];

  //check if first key does not exist yet exist; [106, 136] is error code for key does not exist in decimal
  bool keyExists =
      !(getKeyInfoResponseCode1 == 106 && getKeyInfoResponseCode2 == 136);

  if (keyExists) {
    Uint8List chipPubKey = makePublicKeyFromChipResponse(getKeyInfoData);
    return chipPubKey;
  } else {
    return Uint8List.fromList([]);
  }
}

Future<Uint8List> generatePubAddress(NFCPlatform nfc) async {
  //create new key
  var responseGenerateKey = await nfc.sendCommand(GENERATE_KEY);
  int keySlot = responseGenerateKey[0][0];
  //get key info after generating new key
  Uint8List getKeyInfo = makeGetKeyInfoCommand(keySlot);
  var responseGetKeyInfo = await nfc.sendCommand(getKeyInfo);
  Uint8List getKeyInfoData = responseGetKeyInfo[0];
  int getKeyInfoResponseCode1 = responseGetKeyInfo[1];
  int getKeyInfoResponseCode2 = responseGetKeyInfo[2];

  if (!(getKeyInfoResponseCode1 == 144 && getKeyInfoResponseCode2 == 00)) {
    throw Exception("Error while generating key");
  }
  Uint8List chipPubKey =
      makePublicKeyFromChipResponse(getKeyInfoData); //takes first 20 bytes

  return chipPubKey;
}

//check if first key already exists, if not, generate key. Return key info.
Future<List<dynamic>> createFirstKeypairOnChip(
    NFCPlatform nfc, bool initializeNdef, String sessionId) async {
  bool empty = false;
  //empty UintList
  await nfc.sendCommand(SELECT_APP);

  Uint8List chipPubKey = await getFirstPubKey(nfc);

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
      await initializeNdefTag(nfc, chipEthereumAddressHex, sessionId);
      sendAnalyticsTrace(sessionId, url, "INITIALIZE_NDEF_SUCCESS",
          tags: {"chipWallet": chipEthereumAddressHex.toString()});
    } catch (e) {
      sendAnalyticsTrace(sessionId, "", "INITIALIZE_NDEF_ERROR",
          tags: {"chipWallet": chipEthereumAddress.toString()});
      rethrow;
    }
  }

  return [chipEthereumAddressHex, chipTokenId, empty];
}

// initialize NDEF tag
Future<void> initializeNdefTag(NFCPlatform nfc,
    EthereumAddress chipEthereumAddressHex, String sessionId) async {
  //select Applet
  var selectAppletRes = await nfc.sendCommand(SELECT_NDEF_APP);
  int selectAppletResCode1 = selectAppletRes[1];
  int selectAppletResCode2 = selectAppletRes[2];
  if (!(selectAppletResCode1 == 144 && selectAppletResCode2 == 00)) {
    if (selectAppletResCode1 == 106 && selectAppletResCode2 == 130) {
      // do NOTHING, but report analytics
      sendAnalyticsTrace(
          "$sessionId",
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
            "$sessionId",
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
    BuildContext context, String sessionId, NFCPlatform nfc) async {
  // null comparison below is NOT unnecessary!
  // ignore: unnecessary_null_comparison
  if (nfc == null) {
    NfcManager.instance.stopSession();
    ScaffoldMessenger.of(context).showSnackBar(
      returnSnackBarWidget(
          context.loc.errorHeadingSnackBar, context.loc.noNfc, 'error'),
    );
    sendAnalyticsTrace(sessionId, "", "SCAN_NFC_TYPE_NOT_SUPPORTED");
    //delay for 1 second
    await Future.delayed(const Duration(seconds: 1));
    Navigator.pop(context);
    throw Exception('Tag is not ISO-DEP.');
  }
}

/// returns PUK value (8 byte) or throws exception
Future<String> setPin(NFCPlatform nfc, String pin) async {
  if (pin.length != 4) {
    throw Exception("PIN must be 4 characters long.");
  }

  Uint8List cmd = setPinCommand(pin);
  List<dynamic> res = await nfc.sendCommand(cmd);
  Uint8List puk = res[0];
  int responseCode1 = res[1];
  int responseCode2 = res[2];

  // ERROR (0x69 0x85)
  bool success = (responseCode1 == 0x90 && responseCode2 == 0x00);

  if (success && puk.length == 8) {
    //puk Uint8List to hex string
    String pukHex = bytesToHex(puk, padToEvenLength: true);

    return pukHex;
  } else {
    throw Exception("Error setting pin");
  }
}

/// verify PIN, so that commands requiring authentication are allowed
Future<bool> verifyPin(NFCPlatform nfc, String pin) async {
  if (pin.length != 4) {
    throw Exception("PIN must be 4 characters long.");
  }

  Uint8List cmd = verifyPinCommand(pin);
  List<dynamic> res = await nfc.sendCommand(cmd);
  Uint8List response = res[0];
  int responseCode1 = res[1];
  int responseCode2 = res[2];

  // check if SUCCESS (0x90 0x00)
  if (responseCode1 == 144 && responseCode2 == 0) {
    return true;
  } else if (responseCode1 == 0x69 && responseCode2 == 0x85) {
    throw Exception("PIN not set");
  } else if (responseCode1 == 0x69 && responseCode2 == 0x83) {
    throw Exception("PIN blocked. Please use PUK to unblock.");
  } else {
    throw Exception("Invalid PIN");
  }
}

/// change PIN, returns PUK value (8 byte) or throws exception
Future<String> changePin(NFCPlatform nfc, String oldPin, String newPin) async {
  if (oldPin.length != 4) {
    throw Exception("Old PIN must be 4 characters long.");
  }
  if (newPin.length != 4) {
    throw Exception("New PIN must be 4 characters long.");
  }

  Uint8List cmd = changePinCommand(oldPin, newPin);
  List<dynamic> res = await nfc.sendCommand(cmd);
  Uint8List response = res[0];
  int responseCode1 = res[1];
  int responseCode2 = res[2];

  // check if SUCCESS (0x90 0x00)
  if (responseCode1 == 144 && responseCode2 == 0) {
    Uint8List puk = response.sublist(0, 7);
    Utf8Decoder decoder = const Utf8Decoder();
    return decoder.convert(puk);
  } else if (responseCode1 == 0x69 && responseCode2 == 0x85) {
    throw Exception("PIN not set");
  } else if (responseCode1 == 0x69 && responseCode2 == 0x83) {
    throw Exception("PIN blocked. Please use PUK to unblock.");
  } else if (responseCode1 == 0x6A && responseCode2 == 0x80) {
    throw Exception("Invalid new PIN");
  } else {
    throw Exception("Invalid old PIN");
  }
}

/// remove PIN by entering a PUK (8 byte hex string)
Future<bool> unlockPin(NFCPlatform nfc, String puk) async {
  if (puk.length != 16) {
    throw Exception("PUK must be 16 characters / 8 bytes long.");
  }

  Uint8List pukBytes = hexToBytes(puk);
  Uint8List cmd = unlockPinCommand(pukBytes);
  List<dynamic> res = await nfc.sendCommand(cmd);
  Uint8List response = res[0];
  int responseCode1 = res[1];
  int responseCode2 = res[2];

  // check if SUCCESS (0x90 0x00)
  if (responseCode1 == 144 && responseCode2 == 0) {
    return true;
  } else if (responseCode1 == 0x69 && responseCode2 == 0x85) {
    throw Exception("PIN not set");
  } else if (responseCode1 == 0x69 && responseCode2 == 0x83) {
    throw Exception("PUK blocked.");
  } else {
    throw Exception("Invalid PUK");
  }
}
