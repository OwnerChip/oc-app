import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/config/chains.dart';
import 'package:ownerchip_whitelabel/domain/alchemy/alchemyNftAsset/alchemyNftAsset.dart';
import 'package:ownerchip_whitelabel/domain/blockchainCollectionList/blockchainCollectionList.dart';
import 'package:ownerchip_whitelabel/domain/oc/oc_owned_nft.dart';
import 'package:ownerchip_whitelabel/domain/phygital/purchase/purchase.dart';
import 'package:ownerchip_whitelabel/services/backend/token/backendToken.dart';
import 'package:ownerchip_whitelabel/services/providers/collectionsData.dart';
import 'package:ownerchip_whitelabel/services/providers/nftData.dart';
import 'package:web3dart/web3dart.dart';

final unredeemedVoucherNftsProvider =
    FutureProvider.autoDispose<List<Purchase>>((ref) async {
  List<AlchemyNFTAsset> voucherNftsOwnedByUser =
      await ref.read(voucherNftsOwnedByUserProvider.future);
  List<Future<List<Purchase>>> unredeemedPurchasesList = voucherNftsOwnedByUser
      .map((e) => BackendToken.getUnredeemedPurchases(BigInt.parse(e.tokenId)))
      .toList();

  List<Purchase> unredeemedPurchases = [];

  List<List<Purchase>> unredeemedPurchasesForEachNft =
      await Future.wait(unredeemedPurchasesList);

  //loop over unredeemedPurchasesList and in every purchase add it to unredeemedPurchases, if isRedeemed is false
  for (var unredeemedPurchasesForNft in unredeemedPurchasesForEachNft) {
    for (var purchase in unredeemedPurchasesForNft) {
      if (!purchase.isRedeemed) {
        unredeemedPurchases.add(purchase);
      }
    }
  }

  return unredeemedPurchases;
});

final voucherNftsOwnedByUserProvider =
    FutureProvider.autoDispose<List<AlchemyNFTAsset>>((ref) async {
  Map<int, List<OcOwnedNft>>? nftsForOwnerByChainId =
      await ref.watch(getNftsForOwnerProvider.future);
  if (nftsForOwnerByChainId == null) {
    return [];
  }
  final BlockchainCollectionList collections =
      await ref.read(appCollectionProvider.future);

  List chainIds = chainConfig.keys.toList();
  final List voucherContractsAllChains = [];
  for (var chainId in chainIds) {
    for (var collection in collections.collections[chainId]?.toList() ?? []) {
      if (collection.voucherAddress != null) {
        voucherContractsAllChains.add(collection.voucherAddress);
      }
    }
  }

  List<OcOwnedNft> nftsForOwner = [];
  nftsForOwnerByChainId.forEach((chainId, nfts) {
    nftsForOwner.addAll(nfts);
  });
  List<OcOwnedNft> voucherNftsOwnedByUser = nftsForOwner
      .where((nft) => voucherContractsAllChains
          .contains(EthereumAddress.fromHex(nft.contract.address.toString())))
      .toList();
  final List<AlchemyNFTAsset> alchemyVoucherNftsOwnedByUser =
      voucherNftsOwnedByUser
          .map(
            (e) => AlchemyNFTAsset.fromJson(e.toJson()),
          )
          .toList();
  return alchemyVoucherNftsOwnedByUser;
});
