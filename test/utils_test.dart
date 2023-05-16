import 'package:flutter/foundation.dart';
import 'package:ownerchip_whitelabel/config/collections.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:test/test.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

void main() {
  group('data format helpers', () {
    test('should re-order the collections by chainId', () {
      // arrange
      List<dynamic> rawData = [
        {
          'id': '0x70a2406aeab89f46f322c57e4fce9b9e5eacbd8e',
          'name': "test",
          'chainId': 137
        }
      ];

      // act
      Map<int, List<Collection>> data = groupCollectionsByChainId(rawData);

      // assert
      expect(data, {
        137: [
          Collection(
              EthereumAddress.fromHex(
                  '0x70a2406aeab89f46f322c57e4fce9b9e5eacbd8e'),
              "test")
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

    test('should transform a BigInt number to a hexString', () {
      // arrange
      BigInt tokenId =
          BigInt.parse("643025298622660478098289384378752240690720980366");

      // act
      String ethAddress = convertTokenIdToEthereumAddress(tokenId);

      // assert
      expect(ethAddress, "0x70a2406aeab89f46f322c57e4fce9b9e5eacbd8e");
    });
  });
}
