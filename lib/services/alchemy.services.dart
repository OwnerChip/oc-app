import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/config/chains.dart';
import 'package:ownerchip_whitelabel/domain/alchemy/alchemyNftTokenIdCollectionChainId/alchemyNftTokenIdCollectionChainId.dart';
import 'package:ownerchip_whitelabel/domain/oc/oc_owned_nft.dart';
import 'package:ownerchip_whitelabel/services/common/alchemy/alchemyPaginationResponse.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:web3dart/web3dart.dart';

// A function that fetches NFTs for a given owner address and chainId
Future<AlchemyPaginationResponse<OcOwnedNft>> fetchNFTsForOwner(
  EthereumAddress owner,
  int chainId, {
  List<EthereumAddress>? contractAddresses,
  int pageSize = 10,
  String? pageKey,
}) async {
  if (contractAddresses != null && contractAddresses.length > 45) {
    Sentry.captureMessage(
        'WARNING: Only a max. of 45 contracts are supported by Alchemy API. The rest will be ignored.');
    print(
        'WARNING: Only a max. of 45 contracts are supported by Alchemy API. The rest will be ignored.');
  }
  final options = BaseOptions(
    method: 'GET',
    headers: {'accept': 'application/json'},
  );

  final dio = Dio(options);
  try {
    var response = await dio.get(
      '${chainConfig[chainId]!.alchemyBaseUrl}nft/v3/${dotenv.get('ALCHEMY_API_KEY_POLYGON')}/getNFTsForOwner',
      queryParameters: {
        'owner': owner.hex,
        'withMetadata': 'true',
        'pageSize': pageSize.toString(),
        'excludeFilters[]': ['SPAM', 'AIRDROPS'],
        'pageKey': pageKey,
        'contractAddresses[]': contractAddresses != null
            ? contractAddresses.map((e) => e.hex).toList()
            : [],
      },
    );
    return AlchemyPaginationResponse(
      data: (response.data['ownedNfts'] as List)
          .map((e) => OcOwnedNft.fromJson(e))
          .toList(),
      pageKey: response.data['pageKey'],
    );
  } catch (err) {
    talker.error(err);
    rethrow;
  }
}

Future<AlchemyPaginationResponse<AlchemyNftTokenIdCollectionChainId>>
    fetchMintedOcNftsByAddress(
  EthereumAddress userAddress,
  int chainId, {
  List<EthereumAddress>? contractAddresses,
  String? startPageKey,
  int pageSize = 10,
}) async {
  final options = BaseOptions(
    method: 'POST',
    headers: {'accept': 'application/json', 'content-type': 'application/json'},
  );

  final dio = Dio(options);
  final List mintTransferEvents = [];
  List<String> uniqueTokenIds = [];
  try {
    var response = await dio.post(
      '${chainConfig[chainId]!.alchemyBaseUrl}v2/${dotenv.get('ALCHEMY_API_KEY_POLYGON')}',
      data: {
        "id": 1,
        "jsonrpc": "2.0",
        "method": "alchemy_getAssetTransfers",
        "params": [
          {
            if (startPageKey != null) "pageKey": startPageKey,
            'maxCount': '0x${pageSize.toRadixString(16)}',
            "fromBlock": "0x0",
            "fromAddress": "0x0000000000000000000000000000000000000000",
            "toAddress": userAddress.hex,
            "category": ["erc721", "erc1155"],
            "contractAddresses": contractAddresses != null
                ? contractAddresses.map((e) => e.hex).toList()
                : [],
          }
        ]
      },
    );

    final transfers = response.data['result']['transfers'];
    //loop over transfers and add to mintTransferEvents
    for (var i = 0; i < transfers.length; i++) {
      if (uniqueTokenIds.contains(transfers[i]['tokenId'])) {
        continue;
      }
      uniqueTokenIds.add(transfers[i]['tokenId']);
    }

    mintTransferEvents.addAll(response.data['result']['transfers']);

    //minted
    List<AlchemyNftTokenIdCollectionChainId> mintedNftEvents =
        mintTransferEvents.map((e) {
      return AlchemyNftTokenIdCollectionChainId(
          chainId: 137, //TODO: make dynamic
          nftTokenId: e['tokenId'],
          collectionAddress: e['rawContract']['address'],
          minterAddress: e['to']);
    }).toList();

    List<AlchemyNftTokenIdCollectionChainId> uniqueMintedNftEvents = [];

    //loop over unique token ids
    for (var i = 0; i < uniqueTokenIds.length; i++) {
      final lastMintEvent = mintedNftEvents.lastWhere(
        //get the last mint event for each unique token id, only if the last minter is current user
        (element) {
          return element.nftTokenId == uniqueTokenIds[i] &&
              EthereumAddress.fromHex(element.minterAddress) == userAddress;
        },
        orElse: () => AlchemyNftTokenIdCollectionChainId(
            nftTokenId: '',
            collectionAddress: '',
            chainId: chainId,
            minterAddress: ''),
      );
      if (lastMintEvent.nftTokenId != '') {
        uniqueMintedNftEvents.add(lastMintEvent);
      }
    }

    final key = response.data["result"]['pageKey'];
    return AlchemyPaginationResponse(
      data: uniqueMintedNftEvents,
      pageKey: key == startPageKey ? null : key,
    );
  } catch (err) {
    print(err);
    rethrow;
  }
}

Future<AlchemyPaginationResponse<AlchemyNftTokenIdCollectionChainId>>
    getNotBurnedMintedOcNftsByAddress(
  EthereumAddress userAddress,
  int chainId, {
  List<EthereumAddress>? contractAddresses,
  String? startPageKey,
  int pageSize = 15,
}) async {
  final options = BaseOptions(
    method: 'GET',
    headers: {
      'accept': 'application/json',
    },
  );

  final dio = Dio(options);
  dio.interceptors.add(
    TalkerDioLoggerExtension.instance,
  );
  List<AlchemyNftTokenIdCollectionChainId> filteredNfts = [];

  String? lastPageKey = startPageKey;

  for (;;) {
    AlchemyPaginationResponse<AlchemyNftTokenIdCollectionChainId> mintedNfts =
        await fetchMintedOcNftsByAddress(
      userAddress,
      chainId,
      contractAddresses: contractAddresses,
      startPageKey: lastPageKey,
      pageSize: 25,
    );

    //TODO: I think this only works for a max of 45 NFTs before Error code 429 too many requests from Alchemy
    var responses = await Future.wait(
      mintedNfts.data.map((nft) => dio.get(
            '${chainConfig[chainId]!.alchemyBaseUrl}nft/v3/${dotenv.get('ALCHEMY_API_KEY_POLYGON')}/getOwnersForNFT',
            queryParameters: {
              "contractAddress": nft.collectionAddress,
              "tokenId": nft.nftTokenId
            },
          )),
    );

    filteredNfts.addAll(responses
        .asMap()
        .entries
        .where((entry) {
          return !entry.value.data['owners']
              .contains('0x0000000000000000000000000000000000000000');
        })
        .map((i) => mintedNfts.data[i.key])
        .toList());

    if ((mintedNfts.pageKey == lastPageKey) ||
        filteredNfts.length >= pageSize) {
      lastPageKey = mintedNfts.pageKey;
      break;
    }

    lastPageKey = mintedNfts.pageKey;
  }

  return AlchemyPaginationResponse(
    data: filteredNfts,
    pageKey: filteredNfts.isEmpty ? null : lastPageKey,
  );
}

//call get metadata batch with filtered NFTs and then pass the fetched data to the UI
Future<dynamic> getNFTMetadataBatch(int chainId, List tokens) async {
  final options = BaseOptions(
    method: 'POST',
    headers: {
      'accept': 'application/json',
      'content-type': 'application/json',
    },
  );

  final dio = Dio(options);

  var response = await dio.post(
    '${chainConfig[chainId]!.alchemyBaseUrl}nft/v3/${dotenv.get('ALCHEMY_API_KEY_POLYGON')}/getNFTMetadataBatch',
    data: {"tokens": tokens.toList(), "refreshCache": false},
  );

  return response.data;
}

Future<dynamic> updateAlchemyNftCache(
    int chainId, EthereumAddress contract) async {
  final options = BaseOptions(
    method: 'GET',
    headers: {'accept': 'application/json'},
  );

  final dio = Dio(options);
  try {
    var _ = await dio.get(
      '${chainConfig[chainId]!.alchemyBaseUrl}nft/v3/${dotenv.get('ALCHEMY_API_KEY_POLYGON')}/invalidateContract',
      queryParameters: {'contractAddress': contract.hex},
    );
  } catch (e) {
    Sentry.captureException(e);
  }
}
