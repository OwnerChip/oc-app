import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:ownerchip_whitelabel/config/collections.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:test/test.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'package:ownerchip_whitelabel/services/nfc.services.dart';

void main() {
  group("command helper", () {
    test("return a valid set pin command", () {
      final res = setPinCommand("1234");
      expect(res, [0x00, 0x40, 0x00, 0x00, 0x04, 49, 50, 51, 52, 0x08]);
    });
  });

  group('data format helpers', () {
    test('should re-order the collections by chainId', () {
      // arrange
      List<dynamic> rawData = [
        {
          "address": "0x1787f9469238E2113CdF83e15F169FBA15F884f5",
          "name": "OC Demo Collection",
          "symbol": "DEMO",
          "created_at": "2023-03-02",
          "chainId": 137
        }
      ];

      // act
      final data = groupCollectionsByChainId(rawData);

      // assert
      expect(data, {
        137: [
          Collection(
              EthereumAddress.fromHex(
                  '0x1787f9469238E2113CdF83e15F169FBA15F884f5'),
              "OC Demo Collection")
        ]
      });
    });
  });

  group('bigInt helpers', () {
    test('should parse a hex string to BigInt number', () {
      // arrange
      Uint8List pubKey = Uint8List.fromList([
        122,
        88,
        136,
        89,
        86,
        209,
        52,
        249,
        9,
        89,
        204,
        102,
        207,
        33,
        1,
        207,
        105,
        180,
        35,
        124,
        52,
        95,
        7,
        2,
        151,
        134,
        230,
        178,
        235,
        15,
        141,
        211,
        130,
        95,
        126,
        206,
        107,
        57,
        29,
        254,
        168,
        119,
        170,
        16,
        237,
        107,
        3,
        221,
        17,
        208,
        115,
        78,
        216,
        154,
        124,
        25,
        16,
        91,
        172,
        170,
        106,
        17,
        54,
        73
      ]);
      Uint8List ethAddressBytes = publicKeyToAddress(pubKey);

      // act
      BigInt tokenId = hexToBigInt(ethAddressBytes);

      // assert
      expect(tokenId.toString(),
          "643025298622660478098289384378752240690720980366");
    });

    test(
        'should transform a hex with a leading 0 to a valid BigInt and back to hexString',
        () {
      //arrange
      String ethAddress = "0x0ae7a580a3101f78bade64da3257abb20ad309af";

      //act 1
      BigInt tokenId = hexToBigInt(hexToBytes(ethAddress));

      //assert 1
      expect(tokenId.toString(),
          "62255797149168553891434335013600620774643927471");

      //act 2
      String ethAddress2 = convertTokenIdToEthereumAddress(tokenId);

      //assert 2
      expect(ethAddress2, ethAddress);
    });

    test('should transform a BigInt number to a hexString', () {
      // arrange
      BigInt tokenId =
          BigInt.parse("643025298622660478098289384378752240690720980366");

      // act
      String ethAddress = convertTokenIdToEthereumAddress(tokenId).hex;

      // assert
      expect(ethAddress, "0x70a2406aeab89f46f322c57e4fce9b9e5eacbd8e");
    });
  });
}
