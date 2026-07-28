import 'dart:typed_data';

import 'package:reown_appkit/reown_appkit.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';


class OwnercardData {
  final String name;
  final int appId;
  final EthereumAddress ownerCard;

  const OwnercardData({
    required this.name,
    required this.appId,
    required this.ownerCard,
  });

  static EthereumAddress fromPubKeyZeros(Uint8List pubKey) {
    return EthereumAddress.fromHex(
        "0x${bytesToHex(publicKeyToAddress(pubKey))}");
  }


  static bool isOwnerCard(EthereumAddress address) {
    return instance.any((element) => element.ownerCard == address);
  }

  static List<OwnercardData> instance = [
    OwnercardData(
      name: 'OwnerChip',
      appId: 100,
      ownerCard:
          EthereumAddress.fromHex('0x3e873dd1a384860640dff4a78b80f95907ccc3c5'),
    ),
    OwnercardData(
      name: 'Stebo',
      appId: 101,
      ownerCard:
          EthereumAddress.fromHex('0xdb166d2468d111bba8f80904cfd8143cebd07507'),
    ),
  ];
}
