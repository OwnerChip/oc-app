import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/config/chains.dart';
import 'package:ownerchip_whitelabel/domain/chipInfoModel/chipInfoModel.dart';
import 'package:ownerchip_whitelabel/domain/tokenChainAndCollection/tokenChainAndCollection.dart';
import 'package:ownerchip_whitelabel/services/backend/backend.services.dart';
import 'package:ownerchip_whitelabel/services/providers/chipData.dart';
import 'package:ownerchip_whitelabel/services/providers/nftData.dart';
import 'package:ownerchip_whitelabel/services/web3.services.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:web3dart/web3dart.dart';

//flutter futureprovider that calls getEthPrice()

final ethPriceProvider =
    FutureProvider.autoDispose.family<Map, String>((ref, cryptoSymbol) async {
  final Map ethPrice = await getEthPrice(cryptoSymbol);
  return ethPrice;
});

final lastSellerAddressProvider =
    FutureProvider.autoDispose<EthereumAddress>((ref) async {
  final ChipInfoModel chipInfo = ref.watch(chipInfoProvider);
  final TokenChainAndCollection tokenInfo =
      await ref.watch(findTokenProvider(chipInfo.tokenId).future);
  final EthereumAddress controllerContractAddress = EthereumAddress.fromHex(
      chainConfig[tokenInfo.chainId]!.controllerContract);

  final EthereumAddress lastSellerAddress = await getLastSellerAddress(
      getRPCUrlFromChainId(tokenInfo.chainId),
      controllerContractAddress,
      tokenInfo.tokenId);
  return lastSellerAddress;
});
