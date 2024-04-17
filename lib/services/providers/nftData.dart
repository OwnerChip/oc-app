import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/config/chains.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/domain/alchemyTypes.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/domain/tokenTypes.dart';
import 'package:ownerchip_whitelabel/services/alchemy.services.dart';
import 'package:ownerchip_whitelabel/services/backend.services.dart';
import 'package:ownerchip_whitelabel/services/ipfs.services.dart';
import 'package:ownerchip_whitelabel/services/providers/collectionsData.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:ownerchip_whitelabel/services/web3.services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:web3dart/web3dart.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:ownerchip_whitelabel/services/providers/chipData.dart';

//**** TOKEN DATA ****

final findTokenProvider = FutureProvider.autoDispose
    .family<TokenChainAndCollection, BigInt>((ref, tokenId) async {
  var result = await Future.wait<TokenChainAndCollection>(
      chainConfig.keys.map((chainId) async {
    EthereumAddress collectionId = await getCollectionId(
        chainConfig[chainId]!.rpcUrl,
        chainConfig[chainId]!.registryContract,
        tokenId);

    return TokenChainAndCollection(chainId, collectionId, tokenId);
  }));

  TokenChainAndCollection tokenInfo = result.firstWhere(
      (element) => element.collectionId != zeroAddress,
      orElse: () => TokenChainAndCollection(0, zeroAddress,
          tokenId)); //if token does not exist, zero address is returned as collection
  return tokenInfo;
});

//****NFT OWNER ****

final nftOwnerProvider =
    FutureProvider.autoDispose<EthereumAddress>((ref) async {
  // watch chipInfoProvider
  final ChipInfoModel chipInfo = ref.watch(chipInfoProvider);
  final TokenChainAndCollection config =
      await ref.watch(findTokenProvider(chipInfo.tokenId).future);
  // ERROR HANDLING
  if (config.chainId == 0 || config.collectionId == zeroAddress) {
    return Future.error(
        'No owner found.'); //If you want to change the "No owner found." error message, please double check if no other code depends on this string
  }
  EthereumAddress nftOwner = await getTwinOwner(
      getRPCUrlFromChainId(config.chainId),
      config.collectionId,
      chipInfo.tokenId);

  return nftOwner;
});

//**NFT APPROVAL CHECKER */
final nftApprovalProvider =
    FutureProvider.autoDispose<EthereumAddress>((ref) async {
  // watch chipInfoProvider
  final ChipInfoModel chipInfo = ref.watch(chipInfoProvider);
  final TokenChainAndCollection config =
      await ref.watch(findTokenProvider(chipInfo.tokenId).future);
  // ERROR HANDLING
  if (config.chainId == 0 || config.collectionId == zeroAddress) {
    return Future.error('No approval found.');
  }
  EthereumAddress nftApproval = await getApproved(
      getRPCUrlFromChainId(config.chainId),
      config.collectionId,
      chipInfo.tokenId);

  return nftApproval;
});

//****NFT METADATA****

final contractNameProvider = FutureProvider.autoDispose<String>((ref) async {
  final ChipInfoModel chipInfo = ref.watch(chipInfoProvider);
  final TokenChainAndCollection tokenInfo =
      await ref.watch(findTokenProvider(chipInfo.tokenId).future);
  return getContractName(
      getRPCUrlFromChainId(tokenInfo.chainId), tokenInfo.collectionId);
});

final nftMetadataProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, BigInt>((ref, tokenId) async {
  final ChipInfoModel chipInfo = ref.watch(chipInfoProvider);
  final TokenChainAndCollection config =
      await ref.watch(findTokenProvider(chipInfo.tokenId).future);
  // ERROR HANDLING (config chainId & collectionId are 0)
  if (config.chainId == 0 || config.collectionId == zeroAddress) {
    throw 'Token does not exist.';
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

//**** CREATOR DATA ****

final creatorDataProvider =
    FutureProvider.autoDispose<CreatorData>((ref) async {
  ChipInfoModel chipInfo = ref.watch(chipInfoProvider);
  try {
    final CreatorData creatorData =
        await getCreatorData(chipInfo.chipEthereumAddress);
    return creatorData;
  } catch (err) {
    rethrow;
  }
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
  EthereumAddress voucherTokenOwner = await getVoucherOwner(
      getRPCUrlFromChainId(config.chainId),
      voucherContractAddress,
      chipInfo.tokenId);
  return voucherTokenOwner;
});

final getNftsForOwnerProvider = FutureProvider.autoDispose<Map?>((ref) async {
  List chainIds = chainConfig.keys.toList();
  //remove polygon mumbai testnet from chainIds, so that we do not use alchemy APIs for this chain
  chainIds.remove(80001);
  final UserSession? userSession = ref.read(userSessionProvider);
  final EthereumAddress? walletAddress = userSession?.userWalletAddress;

  //call fetchNFTsForOwner for each chainId; use Future.wait to wait for all futures to complete
  final Map chainIdToNfts = {};
  try {
    var allFailed = true; // Flag to track if all futures fail

    var result = await Future.wait(
      chainIds.map((chainId) async {
        try {
          final List nftsForOwner =
              await fetchNFTsForOwner(walletAddress!, chainId);
          chainIdToNfts[chainId] = nftsForOwner;
          allFailed = false;
        } catch (e) {
          print('Error fetching NFTs from Alchemy for chainId $chainId: $e');
          Sentry.captureException(e);
        }
        return chainIdToNfts;
      }),
      eagerError: false,
    );
    if (allFailed) {
      throw Exception(
          'Fetching NFTs for owner failed on all chains. (in getNftsForOwnerProvider())');
    }
    return chainIdToNfts;
  } catch (err) {
    rethrow;
  }
});

final getOcNftsForOwner = FutureProvider.autoDispose<List?>((ref) async {
  List chainIds = chainConfig.keys.toList();
  final UserSession? userSession = ref.read(userSessionProvider);
  final EthereumAddress? walletAddress = userSession?.userWalletAddress;

  final BlockchainCollectionList ocCollections =
      await ref.watch(appCollectionProvider.future);

  //call fetchNFTsForOwner for each chainId; use Future.wait to wait for all futures to complete
  final List nftList = [];
  try {
    var allFailed = true; // Flag to track if all futures fail

    var result = await Future.wait(
      chainIds.map((chainId) async {
        try {
          final List nftsForOwner = await fetchNFTsForOwner(
              walletAddress!, chainId,
              contractAddresses: ocCollections.collections[chainId]
                  ?.map((e) => e.id)
                  .toList());
          allFailed = false;
          nftList.addAll(nftsForOwner);
        } catch (e) {
          print('Error fetching NFTs from Alchemy for chainId $chainId: $e');
          Sentry.captureException(e);
        }
        return nftList;
      }),
      eagerError: false,
    );

    if (allFailed) {
      throw Exception(
          'Fetching NFTs for owner failed on all chains. (in getOcNftsForOwner())');
    }

    return nftList;
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
  for (var chainId in chainIds) {
    for (var collection in collections.collections[chainId]?.toList() ?? []) {
      if (collection.voucherAddress != null) {
        voucherContractsAllChains.add(collection.voucherAddress);
      }
    }
  }

  List nftsForOwner = [];
  nftsForOwnerByChainId.forEach((chainId, nfts) {
    nftsForOwner.addAll(nfts);
  });
  List voucherNftsOwnedByUser = nftsForOwner
      .where((nft) => voucherContractsAllChains.contains(
          EthereumAddress.fromHex(nft['contract']['address'].toString())))
      .toList();
  final List<AlchemyNFTAsset> alchemyVoucherNftsOwnedByUser =
      voucherNftsOwnedByUser.map((e) => AlchemyNFTAsset.fromJson(e)).toList();
  return alchemyVoucherNftsOwnedByUser;
});

// OFFER DATA

final activeOffersProvider =
    FutureProvider.autoDispose<List<ActiveOffer>>((ref) async {
  try {
    final CreatorData creatorData = await ref.read(creatorDataProvider.future);
    return creatorData.tokenForWhichCreatorDataWasRequested.activeOffers;
  } catch (err) {
    return [];
  }
});
