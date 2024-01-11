import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/config/chains.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/domain/alchemyTypes.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/domain/phygitalTradeTypes.dart';
import 'package:ownerchip_whitelabel/services/alchemy.services.dart';
import 'package:ownerchip_whitelabel/services/backend.services.dart';
import 'package:ownerchip_whitelabel/services/ipfs.services.dart';
import 'package:ownerchip_whitelabel/services/providers/collectionsData.dart';
import 'package:ownerchip_whitelabel/services/providers/nftData.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:ownerchip_whitelabel/services/web3.services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web3dart/web3dart.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:ownerchip_whitelabel/services/providers/chipData.dart';

final unredeemedVoucherNftsProvider =
    FutureProvider.autoDispose<List<Purchase>>((ref) async {
  List<AlchemyNFTAsset> voucherNftsOwnedByUser =
      await ref.read(voucherNftsOwnedByUserProvider.future);
  List<Future<List<Purchase>>> unredeemedPurchasesList = voucherNftsOwnedByUser
      .map((e) => getUnredeemedPurchases(BigInt.parse(e.tokenId)))
      .toList();

  List<Purchase> unredeemedPurchases = [];

  List<List<Purchase>> unredeemedPurchasesForEachNft =
      await Future.wait(unredeemedPurchasesList);

  //loop over unredeemedPurchasesList and in every purchase add it to unredeemedPurchases, if isRedeemed is false
  for (var unredeemedPurchasesForNft in unredeemedPurchasesForEachNft) {
    for (var purchase in unredeemedPurchasesForNft) {
      if (purchase.shippingInfo == null) {
        unredeemedPurchases.add(purchase);
      }
    }
  }

  return unredeemedPurchases;
});

//**** Voucher NFT DATA ****

final voucherTokenOwnerProvider =
    FutureProvider.autoDispose<EthereumAddress?>((ref) async {
  EthereumAddress? voucherContractAddress =
      await ref.watch(voucherContractProvider.future);
  if (voucherContractAddress == null) {
    return null;
  }
  final ChipInfoModel chipInfo = ref.watch(chipInfoProvider);
  final TokenChainAndCollection config =
      await ref.watch(findTokenProvider(chipInfo.tokenId).future);
  EthereumAddress voucherTokenOwner = await getOwner(
      getRPCUrlFromChainId(config.chainId),
      voucherContractAddress,
      chipInfo.tokenId);
  return voucherTokenOwner;
});

final getNftsForOwnerProvider = FutureProvider.autoDispose<Map?>((ref) async {
  List chainIds = chainConfig.keys.toList();
  final UserSession? userSession = ref.read(userSessionProvider);
  final EthereumAddress? walletAddress = userSession?.userWalletAddress;

  //call fetchNFTsForOwner for each chainId; use Future.wait to wait for all futures to complete
  final Map chainIdToNfts = {};
  try {
    var result = await Future.wait(chainIds.map((chainId) async {
      final Map nftsForOwner = await fetchNFTsForOwner(walletAddress!, chainId);
      chainIdToNfts[chainId] = nftsForOwner;
      return chainIdToNfts;
    }));
    return chainIdToNfts;
  } catch (err) {
    rethrow;
  }
});

final voucherNftsOwnedByUserProvider =
    FutureProvider.autoDispose<List<AlchemyNFTAsset>>((ref) async {
  final Map? nftsForOwnerByChainId =
      await ref.watch(getNftsForOwnerProvider.future);
  if (nftsForOwnerByChainId == null) {
    return [];
  }
  final BlockchainCollectionList collections =
      await ref.read(appCollectionProvider.future);

  List chainIds = chainConfig.keys.toList();
  final List voucherContractsAllChains = [];
  //TODO: extract all voucher contracts from collections.collections
  for (var chainId in chainIds) {
    for (var collection in collections.collections[chainId]?.toList() ?? []) {
      if (collection.voucherAddress != null) {
        voucherContractsAllChains.add(collection.voucherAddress);
      }
    }
  }

  List nftsForOwner = [];
  nftsForOwnerByChainId.forEach((chainId, nfts) {
    nftsForOwner.addAll(nfts["ownedNfts"]);
  });
  List voucherNftsOwnedByUser = nftsForOwner
      .where((nft) => voucherContractsAllChains.contains(
          EthereumAddress.fromHex(nft['contract']['address'].toString())))
      .toList();
  final List<AlchemyNFTAsset> alchemyVoucherNftsOwnedByUser =
      voucherNftsOwnedByUser.map((e) => AlchemyNFTAsset.fromJson(e)).toList();
  return alchemyVoucherNftsOwnedByUser;
});
