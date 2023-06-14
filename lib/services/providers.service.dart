import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/services/backend.services.dart';
import 'package:ownerchip_whitelabel/services/ipfs.services.dart';
import 'package:ownerchip_whitelabel/services/web3.services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/config/chains.dart';
import 'package:ownerchip_whitelabel/config/collections.dart';
import 'package:web3dart/web3dart.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:flutter/services.dart';
import 'package:web3dart/crypto.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

//****WALLETCONNECT****

//wallet connect 2 provider
final wcProvider = StateProvider<Web3App?>((ref) {
  return null;
});

final wcSessionProvider = StateProvider<SessionData?>((ref) {
  return null;
});

final userAddressProvider = StateProvider<EthereumAddress>((ref) {
  final session = ref.watch(wcSessionProvider);
  final addr = session != null
      ? EthereumAddress.fromHex(
          session.namespaces['eip155']!.accounts[0].substring(9))
      : zeroAddress;
  return addr;
});

//**** SIGNATIURE DATA */

class SignatureDataNotifier extends StateNotifier<SignatureData> {
  SignatureDataNotifier()
      : super(SignatureData(
            hashedMsg: Uint8List(0),
            signature: MsgSignature(BigInt.from(0), BigInt.from(0), 0)));

  void setSignatureData(SignatureData signatureData) {
    state.hashedMsg = signatureData.hashedMsg;
    state.signature = signatureData.signature;
  }
}

final signatureDataProvider =
    StateNotifierProvider<SignatureDataNotifier, SignatureData>((ref) {
  return SignatureDataNotifier();
});

//****CHIP INFO****

class ChipInfoNotifier extends StateNotifier<ChipInfoModel> {
  ChipInfoNotifier()
      : super(ChipInfoModel(
            chipEthereumAddress: zeroAddress, tokenId: BigInt.from(0)));

  void setTokenId(BigInt tokenId) {
    state.tokenId = tokenId;
  }

  void setChipEthereumAddress(EthereumAddress chipEthereumAddress) {
    state.chipEthereumAddress = chipEthereumAddress;
  }

  void setChipToInitialized() {
    state.chipIsInitialized = true;
  }
}

final chipInfoProvider =
    StateNotifierProvider<ChipInfoNotifier, ChipInfoModel>((ref) {
  return ChipInfoNotifier();
});

// **** COLLECTIONS ****

/// get all collections associated with the app (basis for filtering for MINTER_ROLE)
final appCollectionProvider =
    FutureProvider.autoDispose<BlockchainCollectionList>((ref) async {
  BlockchainCollectionList collections;

  // first, try to get the collections from the backend
  try {
    final rawCollections = await getAppCollections();
    collections =
        BlockchainCollectionList(groupCollectionsByChainId(rawCollections));
  } catch (e) {
    print("Error getting collections from backend: $e");
    // if the backend is not available, get the collections from the config file
    collections = allCollections;
  }
  return collections;
});

/// CHECK ALL COLLECTIONS IF USER HAS MINTER ROLE
final findAllMinterRolesProvider =
    FutureProvider.autoDispose<BlockchainCollectionList>((ref) async {
  final wc = ref.watch(wcProvider);
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
      res.add(Collection(collection.id, collection.name, chainId: chainId));
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
    if (wc != null &&
        wc.getActiveSessions().isNotEmpty &&
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

final findTokenProvider = FutureProvider.autoDispose
    .family<TokenInfoObject, BigInt>((ref, tokenId) async {
  var result =
      await Future.wait<TokenInfoObject>(chainConfig.keys.map((chainId) async {
    EthereumAddress collectionId = await getCollectionId(
        chainConfig[chainId]!.rpcUrl,
        chainConfig[chainId]!.registryContract,
        tokenId);

    return TokenInfoObject(chainId, collectionId, tokenId);
  }));

  return result.firstWhere((element) => element.collectionId != zeroAddress,
      orElse: () => TokenInfoObject(0, zeroAddress, tokenId));
});

//****NFT OWNER ****

final nftOwnerProvider =
    FutureProvider.autoDispose<EthereumAddress>((ref) async {
  // watch chipInfoProvider
  final ChipInfoModel chipInfo = ref.watch(chipInfoProvider);
  final TokenInfoObject config =
      await ref.watch(findTokenProvider(chipInfo.tokenId).future);
  // ERROR HANDLING
  if (config.chainId == 0 || config.collectionId == zeroAddress) {
    return Future.error('No owner found.');
  }
  EthereumAddress nftOwner = await getOwner(
      getRPCUrlFromChainId(config.chainId),
      config.collectionId,
      chipInfo.tokenId);

  return nftOwner;
});

//****NFT METADATA****

final contractNameProvider = FutureProvider.autoDispose<String>((ref) async {
  final ChipInfoModel chipInfo = ref.watch(chipInfoProvider);
  final TokenInfoObject tokenInfo =
      await ref.watch(findTokenProvider(chipInfo.tokenId).future);
  return getContractName(
      getRPCUrlFromChainId(tokenInfo.chainId), tokenInfo.collectionId);
});

final nftMetadataProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, BigInt>((ref, tokenId) async {
  final ChipInfoModel chipInfo = ref.watch(chipInfoProvider);
  final TokenInfoObject config =
      await ref.watch(findTokenProvider(chipInfo.tokenId).future);
  // ERROR HANDLING (config chainId & collectionId are 0)
  if (config.chainId == 0 || config.collectionId == zeroAddress) {
    return {};
  }
  String tokenUri = await getTokenUri(
      getRPCUrlFromChainId(config.chainId), config.collectionId, tokenId);
  String cid = getCidFromIpfsLink(tokenUri);
  var result = await downloadMetadataFromIPFS(cid);
  return result;
});

final nftImageProvider =
    FutureProvider.autoDispose.family<String, BigInt>((ref, tokenId) async {
  final Map<String, dynamic> nftMetadata =
      await ref.watch(nftMetadataProvider(tokenId).future);
  // ERROR HANDLING (nftMetadata is empty)
  if (nftMetadata.isEmpty) {
    return '';
  }
  String cid = getCidFromIpfsLink(nftMetadata['image']);
  String imageUri = "${dotenv.get('IPFS_GATEWAY')}$cid";
  return imageUri;
});

final blockchainExplorerUrlProvider =
    FutureProvider.autoDispose<Uri>((ref) async {
  final ChipInfoModel chipInfo = ref.watch(chipInfoProvider);
  final TokenInfoObject tokenInfo =
      await ref.watch(findTokenProvider(chipInfo.tokenId).future);
  final String baseUrl = chainConfig[tokenInfo.chainId]!.blockchainExplorerUrl;
  final String contractAddress = tokenInfo.collectionId.toString();
  String explorerUrl = "$baseUrl/$contractAddress?a=${chipInfo.tokenId}";
  return Uri.parse(explorerUrl);
});

final openseaUrlProvider = FutureProvider.autoDispose<Uri>((ref) async {
  final ChipInfoModel chipInfo = ref.watch(chipInfoProvider);
  final TokenInfoObject tokenInfo =
      await ref.watch(findTokenProvider(chipInfo.tokenId).future);
  final String baseUrl = chainConfig[tokenInfo.chainId]!.openseaUrl;
  final String contractAddress = tokenInfo.collectionId.toString();
  String openseaUrl = "$baseUrl/$contractAddress/${chipInfo.tokenId}";
  return Uri.parse(openseaUrl);
});

final raribleUrlProvider = FutureProvider.autoDispose<Uri>((ref) async {
  final ChipInfoModel chipInfo = ref.watch(chipInfoProvider);
  final TokenInfoObject tokenInfo =
      await ref.watch(findTokenProvider(chipInfo.tokenId).future);
  final String baseUrl = chainConfig[tokenInfo.chainId]!.raribleUrl;
  final String contractAddress = tokenInfo.collectionId.toString();
  String raribleUrl = "$baseUrl/$contractAddress:${chipInfo.tokenId}";
  return Uri.parse(raribleUrl);
});
