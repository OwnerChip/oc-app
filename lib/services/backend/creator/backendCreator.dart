import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/domain/tokenTypes.dart';
import 'package:ownerchip_whitelabel/services/backend/backend.services.dart';
import 'package:ownerchip_whitelabel/services/backend/creator/backendCreatorService.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';
import 'package:web3dart/web3dart.dart';

abstract class BackendCreator extends Backend {
  //get creator info
  static Future<CreatorData> getCreatorData(EthereumAddress tokenId) async {
    final service = BackendCreatorService.instance;
    try {
      final response = await service.getCreatorData(tokenId: tokenId.hex);
      final Map creatorData = response.data;

      bool hasActiveOffer = creatorData["token"]["hasActiveOffer"];

      return CreatorData(
        name: creatorData['name'],
        affiliation: creatorData['affiliation'],
        email: creatorData['email'],
        walletAddress: EthereumAddress.fromHex(creatorData['address']),
        createdAt: DateTime.parse(creatorData['token']['mintedAt']),
        hasActiveOffer: hasActiveOffer,
        tokenForWhichCreatorDataWasRequested:
            Token.fromJson(creatorData['token']),
      );
    } catch (e, st) {
      talker.error(e, st);
      rethrow;
    }
  }

}
