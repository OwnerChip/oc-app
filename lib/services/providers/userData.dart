import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/domain/chipInfoModel/chipInfoModel.dart';
import 'package:ownerchip_whitelabel/domain/tokenChainAndCollection/tokenChainAndCollection.dart';
import 'package:ownerchip_whitelabel/domain/userSession/userSession.dart';
import 'package:ownerchip_whitelabel/services/providers/chipData.dart';
import 'package:ownerchip_whitelabel/services/providers/nftData.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/services/web3.services.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/crypto.dart';

//**** USER SIGNATURE DATA */

final userSignatureProvider = StateProvider.autoDispose<MsgSignature?>((ref) {
  return null;
});

//**** USER BACKEND SESSION DATA */

final userSessionProvider = StateProvider<UserSession?>((ref) {
  return null;
});

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
