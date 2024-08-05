import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

class OwnercardData {
  final String name;
  final int appId;
  final EthereumAddress ownerCard;
  final EthereumAddress certificateCard;

  const OwnercardData({
    required this.name,
    required this.appId,
    required this.ownerCard,
    required this.certificateCard,
  });

  static bool isCertificateCard(EthereumAddress address) {
    return instance.any((element) => element.certificateCard == address);
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
      certificateCard:
          EthereumAddress.fromHex('0x84346de372502e4639cee6e5648010eb9c3f0170'),
    ),
    OwnercardData(
      name: 'Stebo',
      appId: 101,
      ownerCard:
          EthereumAddress.fromHex('0xdb166d2468d111bba8f80904cfd8143cebd07507'),
      certificateCard:
          EthereumAddress.fromHex('0x391ff123aaca2ecb9520ce199542c2a1a0c92a4d'),
    ),
    OwnercardData(
      name: 'Infineon',
      appId: 102,
      ownerCard:
          EthereumAddress.fromHex('0x3ad219eb491f5587bc26738cc9abd842f57e188f'),
      certificateCard:
          EthereumAddress.fromHex('0xc984550050d77b2e65561b75b69c124c4e6010de'),
    ),
    OwnercardData(
      name: 'Stilami',
      appId: 103,
      ownerCard:
          EthereumAddress.fromHex('0x9eb5ac7ce359f50176f98a4b6b6bdbca0cd79185'),
      certificateCard:
          EthereumAddress.fromHex('0x463f50d0e9625dcf672a4e884c1c5fe1710f1e55'),
    ),
  ];
}
