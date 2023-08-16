import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/services/backend.services.dart';
import 'package:ownerchip_whitelabel/services/ipfs.services.dart';
import 'package:ownerchip_whitelabel/services/web3.services.dart';
import 'package:ownerchip_whitelabel/services/attachments.services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/config/chains.dart';
import 'package:ownerchip_whitelabel/config/collections.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:web3dart/web3dart.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:flutter/services.dart';
import 'package:web3dart/crypto.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

//****WALLETCONNECT****

//wallet connect 2 provider
final wcProvider = StateProvider<Web3App?>((ref) {
  return null;
});

final walletTypeProvider = StateProvider<WalletType?>((ref) {
  return null;
});

final wcSessionProvider = StateProvider<SessionData?>((ref) {
  return null;
});

final userAddressProvider = StateProvider<EthereumAddress>((ref) {
  final session = ref.watch(wcSessionProvider);
  final addr = session != null
      ? EthereumAddress.fromHex(
          session.namespaces['eip155']!.accounts[0].split(':').last)
      : zeroAddress;
  return addr;
});

//**** CHIP SIGNATIURE DATA */

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

final chipSignatureDataProvider =
    StateNotifierProvider<SignatureDataNotifier, SignatureData>((ref) {
  return SignatureDataNotifier();
});

//**** USER SIGNATURE DATA */

final userSignatureProvider = StateProvider.autoDispose<MsgSignature?>((ref) {
  return null;
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
    // if the backend is not available, return no collections
    collections = BlockchainCollectionList({});
  }
  return collections;
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
    if (ref.read(backendSessionProvider) != null &&
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

  TokenInfoObject tokenInfo = result.firstWhere(
      (element) => element.collectionId != zeroAddress,
      orElse: () => TokenInfoObject(0, zeroAddress, tokenId));
  return tokenInfo;
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
    return Future.error(
        'No owner found.'); //If you want to change the "No owner found." error message, please double check if no other code depends on this string
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

//this provider fetches all attachments from backend, and saves them to localAttachmentsProvider!
//This is necessary to edit attachments locally!
final fetchAttachmentsProvider = FutureProvider.autoDispose((ref) async {
  //get tokenId from provider
  final ChipInfoModel chipInfo = ref.watch(chipInfoProvider);
  TokenInfoObject tokenInfo =
      await ref.read(findTokenProvider(chipInfo.tokenId).future);

  bool tokenExists = true;
  EthereumAddress nftOwner = zeroAddress;
  try {
    //check if connected wallet is nft owner
    nftOwner = await ref.read(nftOwnerProvider.future);
    print('nftOwner: $nftOwner');
  } catch (e) {
    print(e);
    if (e == 'No owner found.') {
      tokenExists =
          false; //if "No owner found." error is thrown, token does not exist
    }
  }
  final EthereumAddress userWalletAddress = ref.read(userAddressProvider);

  var response;

  //if token does not exist, the collectionId and chainId is given by the selected
  //collection and chain from selectedCollectionIdProvider and selectedChainIdProvider (selected on ChainSelectorScreen).
  //ATTENTION: This relies on the fact that attachments for non existing tokens are only fetched
  //after the user has selected a collection and chain on ChainSelectorScreen (e.g. on MetadataInputScreens)
  //IF token DOES exists, the collectionId is given by the tokenInfo (fetched from Blockchain)
  EthereumAddress collectionId;
  int? chainId = ref.read(selectedChainIdProvider);
  Collection? collection = ref.read(selectedCollectionIdProvider);
  if (!tokenExists && collection != null && chainId != null) {
    collectionId = collection.id;
    chainId = collection.chainId!;
  } else {
    collectionId = tokenInfo.collectionId;
    chainId = tokenInfo.chainId;
  }

  //if connected wallet is nft owner, get all (private and public) attachments
  //if token does not exist, the creator can fetch all attachments. This is
  //necessary to show all previously uploaded attachments in MetadataInputScreens
  if (!tokenExists || nftOwner == userWalletAddress) {
    SignatureData tokenSignatureData = ref.read(chipSignatureDataProvider);

    BackendSession? backendSession = ref.read(backendSessionProvider);
    response = await getPublicAndPrivateAttachmentsFromBackend(
      backendSession!,
      userWalletAddress,
      chainId,
      collectionId,
      chipInfo.tokenId,
    );
  } else {
    //get all public attachments
    response = await getPublicAttachmentsFromBackend(chipInfo.tokenId);
    print(response);
  }
  //create list of attachments
  List<Attachment> attachments = [];
  //create list of attachments
  for (var attachment in response.data) {
    attachments.add(Attachment(
      attachment['title'],
      attachment['name'],
      attachment['is_file'] ? AttachmentType.other : AttachmentType.url,
      attachment['url'],
      attachment['uuid'],
      isFromCreator: attachment['isFromCreator'],
      isPrivate: attachment['is_private'],
    ));
  }

  //set state of attachmentListProvider
  ref.read(localAttachmentsProvider.notifier).state = attachments;

  return attachments;
});

//This provider is used to display attachment data in the UI and to edit attachment data locally (which is then posted to backend)
final localAttachmentsProvider =
    StateProvider.autoDispose<List<Attachment>>((ref) {
  return [];
});

//provider with attachments only where isFromCreator == true
final creatorAttachmentsProvider =
    Provider.autoDispose<List<Attachment>>((ref) {
  final List<Attachment> attachments = ref.watch(localAttachmentsProvider);
  return attachments
      .where((e) => e.isFromCreator != null && e.isFromCreator!)
      .toList();
});

//provider with attachments only where isFromCreator == false
final ownerAttachmentsProvider = Provider.autoDispose<List<Attachment>>((ref) {
  final List<Attachment> attachments = ref.watch(localAttachmentsProvider);
  return attachments
      .where((e) => e.isFromCreator != null && !e.isFromCreator!)
      .toList();
});

final hasMinterRoleProvider = FutureProvider.autoDispose<bool>((ref) async {
  final ChipInfoModel chipInfo = ref.watch(chipInfoProvider);
  final TokenInfoObject tokenInfo =
      await ref.watch(findTokenProvider(chipInfo.tokenId).future);
  final EthereumAddress userWalletAddress = ref.read(userAddressProvider);
  bool hasMinterRole = await checkMinterRole(
      getRPCUrlFromChainId(tokenInfo.chainId),
      tokenInfo.collectionId,
      userWalletAddress);
  return hasMinterRole;
});

final backendSessionProvider = StateProvider<BackendSession?>((ref) {
  return null;
});
