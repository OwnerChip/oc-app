import 'package:flutter/foundation.dart';
import 'package:test/test.dart';
import 'package:owner_chip_admin_demo/utils/signature.service.dart';
import 'package:owner_chip_admin_demo/utils/utils.dart';
import 'package:web3dart/crypto.dart';
import 'dart:convert';

void main() {
  group('signature helpers', () {
    test('extract a signature correctly', () {
      // arrange
      Uint8List sigResp = Uint8List.fromList([
        0,
        15,
        65,
        197,
        0,
        1,
        134,
        35,
        48,
        69,
        2,
        33,
        0,
        135,
        241,
        212,
        97,
        248,
        198,
        177,
        121,
        50,
        161,
        138,
        160,
        252,
        75,
        10,
        165,
        3,
        155,
        52,
        138,
        99,
        159,
        14,
        251,
        240,
        24,
        148,
        151,
        194,
        119,
        8,
        210,
        2,
        32,
        21,
        133,
        179,
        143,
        13,
        70,
        62,
        24,
        197,
        243,
        70,
        205,
        176,
        16,
        176,
        62,
        52,
        173,
        46,
        7,
        93,
        205,
        248,
        169,
        187,
        42,
        63,
        177,
        41,
        121,
        220,
        54,
        144,
        0
      ]);
      String compareTokenId =
          "643025298622660478098289384378752240690720980366";
      String ethAddress = "0x70a2406aeab89f46f322c57e4fce9b9e5eacbd8e";
      Uint8List ethAddressBytes = Uint8List.fromList(utf8.encode(ethAddress));
      BigInt tokenId = hexToBigInt(ethAddressBytes);
      Uint8List msgHash = keccakUtf8(tokenId.toString());

      // act
      MsgSignature sig = extractSignature(tokenId, sigResp);
      Uint8List recoveredPubKey = ecRecover(msgHash, sig);
      Uint8List recoveredAddress = publicKeyToAddress(recoveredPubKey);

      // assert
      expect(compareTokenId, hexToBigInt(recoveredAddress));
    });
  });
}
