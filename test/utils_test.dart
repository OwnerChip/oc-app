import 'package:flutter/foundation.dart';
import 'package:test/test.dart';
import 'package:owner_chip_admin_demo/utils/utils.dart';
import 'dart:convert';

void main() {
  group('bigInt helpers', () {
    test('should parse a hex string to BigInt number', () {
      String ethAddress = "0x70a2406aeab89f46f322c57e4fce9b9e5eacbd8e";
      Uint8List ethAddressBytes = Uint8List.fromList(utf8.encode(ethAddress));
      BigInt tokenId = hexToBigInt(ethAddressBytes);

      expect(tokenId,
          BigInt.parse("643025298622660478098289384378752240690720980366"));
    });
  });
}
