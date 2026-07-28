import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/config/chains.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/services/providers/chipData.dart';
import 'package:ownerchip_whitelabel/services/providers/nftData.dart';
import 'package:ownerchip_whitelabel/services/web3.services.dart';
import 'package:ownerchip_whitelabel/utils/urls.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:web3dart/web3dart.dart';

final blockchainExplorerUrlProvider =
    FutureProvider.autoDispose<Uri>((ref) async {
  final ChipInfoModel chipInfo = ref.watch(chipInfoProvider);
  final TokenChainAndCollection tokenInfo =
      await ref.watch(findTokenProvider(chipInfo.tokenId).future);
  final String baseUrl = chainConfig[tokenInfo.chainId]!.blockchainExplorerUrl;
  final String contractAddress = tokenInfo.collectionId.toString();
  String explorerUrl = "$baseUrl/$contractAddress?a=${chipInfo.tokenId}";
  return Uri.parse(explorerUrl);
});

final webLinkUrlProvider = Provider.autoDispose<Uri>((ref) {
  final ChipInfoModel chipInfo = ref.watch(chipInfoProvider);
  return Uri.parse(getItemOwnerChipUrl(chipInfo.chipEthereumAddress));
});

final openseaUrlProvider = FutureProvider.autoDispose<Uri>((ref) async {
  final ChipInfoModel chipInfo = ref.watch(chipInfoProvider);
  final TokenChainAndCollection tokenInfo =
      await ref.watch(findTokenProvider(chipInfo.tokenId).future);
  final String baseUrl = chainConfig[tokenInfo.chainId]!.openseaUrl;
  late final EthereumAddress contractAddress;
  try {
    contractAddress = await getVoucherContractFromTwin(
        getRPCUrlFromChainId(tokenInfo.chainId), tokenInfo.collectionId);
  } catch (e) {
    contractAddress = tokenInfo.collectionId;
  }
  String openseaUrl =
      "$baseUrl/${contractAddress.toString()}/${chipInfo.tokenId}";
  return Uri.parse(openseaUrl);
});
