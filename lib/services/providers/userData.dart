import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/services/providers/chipData.dart';
import 'package:ownerchip_whitelabel/services/providers/nftData.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/services/web3.services.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/crypto.dart';

//**** USER SIGNATURE DATA */

class _UserSignatureNotifier extends Notifier<MsgSignature?> {
  @override
  MsgSignature? build() => null;
}

final userSignatureProvider =
    NotifierProvider.autoDispose<_UserSignatureNotifier, MsgSignature?>(
        _UserSignatureNotifier.new);

//**** USER BACKEND SESSION DATA */

class _UserSessionNotifier extends Notifier<UserSession?> {
  @override
  UserSession? build() {
    ref.keepAlive();
    return null;
  }
}

final userSessionProvider =
    NotifierProvider<_UserSessionNotifier, UserSession?>(_UserSessionNotifier.new);

class DeferredUserSessionData {
  final UserSession? userSession;
  final WalletType? walletType;

  factory DeferredUserSessionData.empty() {
    return DeferredUserSessionData(
      userSession: null,
      walletType: null,
    );
  }

  DeferredUserSessionData({
    this.userSession,
    this.walletType,
  });
}

class _DeferredUserSessionNotifier extends Notifier<DeferredUserSessionData?> {
  @override
  DeferredUserSessionData? build() {
    ref.keepAlive();
    return null;
  }
}

final deferredUserSessionProvider =
    NotifierProvider<_DeferredUserSessionNotifier, DeferredUserSessionData?>(
        _DeferredUserSessionNotifier.new);

//**** USER HAS MINTER ROLE OR NOT */

final hasMinterRoleProvider = FutureProvider.autoDispose<bool>((ref) async {
  final ChipInfoModel chipInfo = ref.watch(chipInfoProvider);
  final TokenChainAndCollection tokenInfo =
      await ref.watch(findTokenProvider(chipInfo.tokenId).future);
  final EthereumAddress userWalletAddress = ref.read(userAddressProvider);
  bool hasMinterRole = await checkMinterRole(
      getRPCUrlFromChainId(tokenInfo.chainId),
      tokenInfo.collectionId,
      userWalletAddress);
  return hasMinterRole;
});
