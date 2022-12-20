import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/platform_tags.dart';

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

Uint8List GENERATE_KEY = Uint8List.fromList([
  0x00,
  0x02,
  0x00,
  0x00,
  0x01,
]);

Uint8List make_get_key_info_command(hex_key_number) {
  return Uint8List.fromList([
    0x00,
    0x16,
    hex_key_number,
    0x00,
    0x00,
  ]);
}

Uint8List make_signature_command(int hex_key_number, Uint8List data_to_sign) {
  var bytes = BytesBuilder();
  Uint8List a = Uint8List.fromList([
    0x00,
    0x18,
    hex_key_number,
    0x00,
    0x20,
  ]);
  bytes.add(a);
  bytes.add(data_to_sign);
  bytes.add(Uint8List.fromList([0x00]));
  Uint8List res = bytes.toBytes();
  return res;
}

class NFCPlatform {
  var platform = defaultTargetPlatform;
  final NfcTag tag;
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
