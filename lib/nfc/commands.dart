import 'dart:io';

import 'package:flutter/foundation.dart';

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
  print(res);
  return res;
}
