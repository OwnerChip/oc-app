import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/config/chains.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/domain/oc/oc_owned_nft.dart';
import 'package:ownerchip_whitelabel/services/alchemy.services.dart';
import 'package:ownerchip_whitelabel/services/common/alchemy/alchemyPaginationResponse.dart';
import 'package:ownerchip_whitelabel/services/providers/collectionsData.dart';
import 'package:ownerchip_whitelabel/services/providers/nft/nftMintedByUser/nftMintedByUserData.dart';
import 'package:ownerchip_whitelabel/services/providers/nft/paginationNotifier.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:web3dart/web3dart.dart';

class OCNFTsMintedByUserNotifier extends Notifier<OCNFTsMintedByUserData>
    implements IPaginationNotifier {
  @override
  OCNFTsMintedByUserData build() {
    return OCNFTsMintedByUserData.initial();
  }

  Future<List<OcOwnedNft>> _fetchNFTs({
    required Map<int, String?> pageKeys,
    String? key,
    bool ignoreNullKeys = false,
  }) async {
    List chainIds = chainConfig.keys.toList();
    final UserSession? userSession = ref.read(userSessionProvider);
    final EthereumAddress? walletAddress = userSession?.userWalletAddress;

    final BlockchainCollectionList ocCollections =
        await ref.read(appCollectionProvider.future);

    final List nftInfoList = [];
    try {
      var allFailed = true; // Flag to track if all futures fail

      await Future.wait(
        chainIds.map((chainId) async {
          try {
            if (ignoreNullKeys && pageKeys[chainId] == null) {
              return;
            }

            final AlchemyPaginationResponse<dynamic> nftsForOwner =
                await getNotBurnedMintedOcNftsByAddress(
              walletAddress!,
              chainId,
              contractAddresses:
                  ocCollections.collections[chainId]?.map((e) => e.id).toList(),
              pageSize: 10,
              startPageKey: pageKeys[chainId],
            );
            pageKeys[chainId] = nftsForOwner.pageKey;
            allFailed = false;
            nftInfoList.addAll(nftsForOwner.data);
          } on DioException catch (e) {
            talker.error(
                'Error fetching NFTs from Alchemy for chainId $chainId: ${e.response?.data}');
            Sentry.captureException(e);
          } catch (e) {
            talker.error(
                'Error fetching NFTs from Alchemy for chainId $chainId: $e');
            Sentry.captureException(e);
          }
        }),
        eagerError: false,
      );

      if (allFailed) {
        throw Exception(
            'Fetching minted NFTs for creator failed on all chains. (in getOcNftsMintedByUser())');
      }
      List callData = [];
      for (var nft in nftInfoList) {
        callData.add({
          "contractAddress": nft.collectionAddress,
          "tokenId": nft.nftTokenId,
          "type": "ERC721"
        });
      }
      List<dynamic> nftList = [];
      for (var chainId in chainIds) {
        try {
          if (callData.isEmpty) {
            continue;
          }
          var response = await getNFTMetadataBatch(chainId, callData);
          List<dynamic> nfts = response['nfts'];
          nftList.addAll(nfts);
        } catch (e) {
          talker.error(
              'Error fetching batched NFTs from Alchemy for chainId $chainId: $e');
          Sentry.captureException(e);
        }
      }
      // filter out nfts where "name" is null
      return nftList
          .where((nft) => nft['name'] != null)
          .toList()
          .map((nft) => OcOwnedNft.fromJson(nft))
          .toList();
    } catch (e, s) {
      rethrow;
    }
  }

  @override
  Future<void> refreshPage() async {
    state = state.copyWith(
      data: [],
      loading: true,
      page: null,
      canLoadMore: true,
      error: false,
    );

    try {
      final Map<int, String?> pageKeys = {};
      final data = await _fetchNFTs(
        pageKeys: pageKeys,
      );
      state = state.copyWith(
        data: data,
        page: pageKeys,
        loading: false,
        canLoadMore: pageKeys.values.any((element) => element != null),
      );
    } catch (e, s) {
      talker.error('Error refreshing NFTs for owner', e, s);
      Sentry.captureException(e, stackTrace: s);
      state = state.copyWith(
        loading: false,
        error: true,
      );
    }
  }

  @override
  Future<void> loadNextPage() async {
    if (state.loading || !state.canLoadMore) {
      return;
    }

    state = state.copyWith(
      loading: true,
    );

    try {
      final Map<int, String?> pageKeys = Map.from(state.page);
      final data = await _fetchNFTs(
        pageKeys: pageKeys,
        ignoreNullKeys: true,
      );
      final newData = [...state.data];

      // add new NFTs to the list
      // only add NFTs that are not already in the list
      for (var nft in data) {
        if (!newData.any((element) => element.tokenId == nft.tokenId)) {
          newData.add(nft);
        }
      }

      state = state.copyWith(
        loading: false,
        data: newData,
        page: pageKeys,
        canLoadMore: pageKeys.values.any((element) => element != null),
      );
    } catch (e, s) {
      state = state.copyWith(
        loading: false,
        error: true,
      );
      talker.error('Error loading next page of NFTs for owner', e, s);
      Sentry.captureException(e, stackTrace: s);
    }
  }
}
