import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/services/backend.services.dart';
import 'package:ownerchip_whitelabel/services/providers/chipData.dart';
import 'package:ownerchip_whitelabel/services/providers/nftData.dart';
import 'package:ownerchip_whitelabel/services/web3.services.dart';
import 'package:ownerchip_whitelabel/config/collections.dart';
import 'package:web3dart/web3dart.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';

// **** COLLECTIONS ****

/// get all collections associated with the app (basis for filtering for MINTER_ROLE)
final appCollectionProvider =
    FutureProvider.autoDispose<BlockchainCollectionList>((ref) async {
  BlockchainCollectionList collections;

  // first, try to get the collections from the backend
  try {
    final data = await getAppCollections();
    final rawCollections = data['collections'];
    collections =
        BlockchainCollectionList(groupCollectionsByChainId(rawCollections));
  } catch (e) {
    print("Error getting collections from backend: $e");
    // if the backend is not available, return no collections
    collections = BlockchainCollectionList({});
  }
  return collections;
});

final voucherContractAndTwinNftOwnerProvider =
    FutureProvider.autoDispose<List>((ref) async {
  final voucherContractAddress = await ref.read(voucherContractProvider.future);
  final twinNftOwner = await ref.read(nftOwnerProvider.future);
  return [voucherContractAddress, twinNftOwner];
});

final voucherContractProvider =
    FutureProvider.autoDispose<EthereumAddress?>((ref) async {
  final ChipInfoModel chipInfo = ref.watch(chipInfoProvider);

  //watch findTokenProvider
  final TokenChainAndCollection tokenInfo =
      await ref.read(findTokenProvider(chipInfo.tokenId).future);

  final BlockchainCollectionList collections =
      await ref.read(appCollectionProvider.future);

  // get collection in collections.collections[tokenInfo.chainId] with id == tokenInfo.collectionAddress
  final Collection collection = collections.collections[tokenInfo.chainId]!
      .firstWhere((element) => element.id == tokenInfo.collectionId);

  final EthereumAddress? voucherContractAddress = collection.voucherAddress;

  return voucherContractAddress;
});

/// CHECK ALL COLLECTIONS IF USER HAS MINTER ROLE
final findAllMinterRolesProvider =
    FutureProvider.autoDispose<BlockchainCollectionList>((ref) async {
  final wc = ref.watch(wcProvider);
  final wcSession = ref.watch(wcSessionProvider);
  EthereumAddress userWalletAddress = ref.watch(userAddressProvider);
  final unfilteredCollectionsList =
      await ref.read(appCollectionProvider.future);
  //loop through all chains
  List<Future> futures = [];
  List<Collection> res = [];
  bool hasAnyMinterRole = false;

  unfilteredCollectionsList.collections.forEach((chainId, collections) {
    for (var collection in collections) {
      Future<bool> hasMinterRoleFuture = checkMinterRole(
          getRPCUrlFromChainId(chainId), collection.id, userWalletAddress);
      futures.add(hasMinterRoleFuture);
      res.add(Collection(collection.id, collection.name,
          voucherAddress: collection.voucherAddress, chainId: chainId));
    }
  });
  var resRaw = await Future.wait(futures);

  for (var i = 0; i < res.length; i++) {
    res[i].hasMinterRole = resRaw[i];
  }

  // create BlockchainCollectionList from res
  Map<int, List<Collection>> filteredCollections = {};
  for (Collection collection in res) {
    // if collection is OPEN, add it to the list
    if (ref.read(userSessionProvider) != null &&
        collection.id ==
            EthereumAddress.fromHex(
                '0x91930a50a20625f1eb2c2Ce04535fDFF657B5b8a')) {
      collection.hasMinterRole = true;
    }
    if (collection.hasMinterRole!) {
      hasAnyMinterRole = true;
      if (filteredCollections.containsKey(collection.chainId)) {
        filteredCollections[collection.chainId]!.add(collection);
      } else {
        filteredCollections[collection.chainId!] = [collection];
      }
    }
  }

  return BlockchainCollectionList(filteredCollections,
      hasAnyMinterRole: hasAnyMinterRole);
});

// **** CHAIN ID + COLLECTION ID ****

// only used in admin app for selecting the chain
final selectedChainIdProvider = StateProvider.autoDispose<int?>((ref) {
  //return null if col.collections.keys has more than one element else return col.collections.keys.first
  final AsyncValue<BlockchainCollectionList> collectionList =
      ref.watch(findAllMinterRolesProvider);
  final int? res = collectionList.asData != null &&
          collectionList.asData!.value.collections.keys.length == 1
      ? collectionList.asData!.value.collections.keys.first
      : null;
  return res;
});

// only used in admin app for selecting the collection
final selectedCollectionIdProvider =
    StateProvider.autoDispose<Collection?>((ref) {
  final int? chainId = ref.watch(selectedChainIdProvider);
  final AsyncValue<BlockchainCollectionList> collectionList =
      ref.watch(findAllMinterRolesProvider);

  final Collection? res = chainId != null &&
          collectionList.asData != null &&
          collectionList.asData!.value.collections[chainId]!.length == 1
      ? collectionList.asData!.value.collections[chainId]![0]
      : null;
  return res;
});
