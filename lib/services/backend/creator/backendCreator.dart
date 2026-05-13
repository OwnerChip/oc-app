import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/domain/creator/web3AuthDataDto.dart';
import 'package:ownerchip_whitelabel/domain/creator/web3AuthProvidersDto.dart';
import 'package:ownerchip_whitelabel/domain/tokenTypes.dart';
import 'package:ownerchip_whitelabel/services/backend/backend.services.dart';
import 'package:ownerchip_whitelabel/services/backend/creator/backendCreatorService.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:web3dart/web3dart.dart';

import 'payloads/updateWeb3AuthDataPayload.dart';

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

  //update web3auth data
  static Future<Web3AuthDataDto?> updateWeb3AuthData(
      UpdateWeb3AuthDataPayload payload) async {
    final service = BackendCreatorService.instance;
    Web3AuthDataDto? response;
    await service.updateWeb3AuthData(payload: payload).then((res) {
      response = res;
    }).catchError((e, st) {
      Sentry.captureException(
        e,
        stackTrace: st,
      );
    });

    return response;
  }

  //get web3auth providers for the current user
  static Future<Web3AuthProvidersDto?> getWeb3AuthProviders() async {
    final service = BackendCreatorService.instance;
    try {
      return await service.getWeb3AuthProviders();
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      talker.error('Error fetching web3auth providers', e, st);
      return null;
    }
  }
}
