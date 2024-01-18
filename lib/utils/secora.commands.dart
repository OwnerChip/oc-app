import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:web3dart/web3dart.dart';

Uint8List SELECT_APP = Uint8List.fromList([
  0x00,
  0xA4,
  0x04,
  0x00,
  0x0D,
  0xD2,
  0x76,
  0x00,
  0x00,
  0x04,
  0x15,
  0x02,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x12
]);

Uint8List SELECT_NDEF_APP = Uint8List.fromList([
  0x00,
  0xA4,
  0x04,
  0x00,
  0x07,
  0xD2,
  0x76,
  0x00,
  0x00,
  0x85,
  0x01,
  0x01,
  0x00
]);

// Select NDEF File [File ID E104]
// The default File ID of the NDEF file is ‘E104’ (instance created without install parameters).
Uint8List SELECT_NDEF_FILE = Uint8List.fromList([
  0x00,
  0xA4,
  0x00,
  0x0C,
  0x02,
  0xE1,
  0x04,
]);

Uint8List LOCK_NDEF_FILE = Uint8List.fromList([0x80, 0xE1, 0x00, 0x00]);

Uint8List GENERATE_KEY = Uint8List.fromList([
  0x00,
  0x02,
  0x00,
  0x00,
  0x01,
]);

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

Uint8List makeSignatureCommand(int keyNumber, Uint8List dataToSign) {
  var bytes = BytesBuilder();
  Uint8List a = Uint8List.fromList([
    0x00,
    0x18,
    keyNumber,
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
