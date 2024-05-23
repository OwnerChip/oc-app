import 'package:ownerchip_whitelabel/domain/token/token.dart';
import 'package:web3dart/web3dart.dart';

class CreatorData {
  final String name;
  final String affiliation;
  final String email;
  final EthereumAddress walletAddress;
  final DateTime createdAt;
  final bool hasActiveOffer;
  final Token tokenForWhichCreatorDataWasRequested;

  const CreatorData({
    required this.name,
    required this.affiliation,
    required this.email,
    required this.walletAddress,
    required this.createdAt,
    required this.hasActiveOffer,
    required this.tokenForWhichCreatorDataWasRequested,
  });
}
