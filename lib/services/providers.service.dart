import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/services/backend.services.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:ownerchip_whitelabel/services/walletconnect.services.dart';
import 'package:ownerchip_whitelabel/services/ipfs.services.dart';
import 'package:ownerchip_whitelabel/services/web3.services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/config/chains.dart';
import 'package:ownerchip_whitelabel/config/collections.dart';
import 'package:web3dart/web3dart.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:flutter/services.dart';
import 'package:web3dart/crypto.dart';

//****WALLETCONNECT****

final walletConnectProvider =
    StateNotifierProvider<WalletConnector, WalletConnect>((ref) {
  return WalletConnector();
});

final userAddressProvider = FutureProvider.autoDispose<EthereumAddress>((ref) {
  var wc = ref.watch(walletConnectProvider);
  return EthereumAddress.fromHex(wc.session.accounts[0].toLowerCase());
});

class WalletConnector extends StateNotifier<WalletConnect> {
  WalletConnector()
      : super(WalletConnect(
            bridge: 'https://bridge.walletconnect.org',
            clientMeta: const PeerMeta(
              name: 'OwnerChip Demo',
              description: 'Connecting physical objects to the blockchain.',
              url: 'https://walletconnect.org',
              // icons: ["${dotenv.get('IMAGE_ASSETS_BASE_URL')}/app_logo.png"]
            )));
  void resetWalletConnector() async {
    state = await createWalletConnector();
  }
}

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
    final rawCollections = await getAppCollections() as List<Collection>;
    collections =
        groupCollectionsByChainId(rawCollections) as BlockchainCollectionList;
  } catch (e) {
    print("Error getting collections from backend: $e");
    // if the backend is not available, get the collections from the config file
    collections = allCollections;
  }

  return collections;
});

/// CHECK ALL COLLECTIONS IF USER HAS MINTER ROLE
final findAllMinterRolesProvider = FutureProvider.autoDispose
    .family<List<Collection>, EthereumAddress>((ref, userWalletAddress) async {
  var fut = List<Future<Map<String, dynamic>>>.empty(growable: true);

  final blockchainCollectionsList =
      await ref.watch(appCollectionProvider.future);

  //loop through all chains
  blockchainCollectionsList.collections.keys.map((chainId) {
    var collections = blockchainCollectionsList.collections[chainId]!;
    //loop through all collections
    collections.map((collection) {
      Future<bool> hasMinterRole = checkMinterRole(
          getRPCUrlFromChainId(chainId), collection.id, userWalletAddress);
      fut.add({
        "id": collection.id,
        "name": collection.name,
        "chainId": chainId,
        "hasMinterRole": hasMinterRole
      } as Future<Map<String, dynamic>>);
    });
  });
  var resRaw = await Future.wait(fut);
  List<Collection> res = resRaw
      .map((e) => Collection(e["id"], e["name"],
          chainId: e["chainId"], hasMinterRole: e["hasMinterRole"]))
      .toList();
  return res;
});

// **** CHAIN ID + COLLECTION ID ****

// only used in admin app for selecting the chain
final relevantCollectionsProvider =
    FutureProvider.autoDispose<BlockchainCollectionList>((ref) async {
  var userAddress = await ref.watch(userAddressProvider.future);
  var relevantCollections =
      await ref.watch(findAllMinterRolesProvider(userAddress).future);
  var res = groupCollectionsByChainId(relevantCollections);
  return BlockchainCollectionList(res);
});

// only used in admin app for selecting the chain
final selectedChainIdProvider = StateProvider.autoDispose
    .family<int, BlockchainCollectionList>(
        (ref, col) => col.collections.keys.first);

// only used in admin app for selecting the collection
final selectedCollectionIdProvider = StateProvider.autoDispose
    .family<EthereumAddress, BlockchainCollectionList>((ref, col) {
  final int chainId = ref.watch(selectedChainIdProvider(col));
  return col.collections[chainId]![0].id;
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
