import 'package:dio/dio.dart';
import 'package:ownerchip_whitelabel/domain/tokenTypes.dart';
import 'package:web3dart/web3dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/config/chains.dart';

// A function that fetches NFTs for a given owner address and chainId
Future<List> fetchNFTsForOwner(EthereumAddress owner, int chainId,
    {List<EthereumAddress>? contractAddresses}) async {
  if (contractAddresses != null && contractAddresses.length > 45) {
    print(
        'WARNING: Only a max. of 45 contracts are supported by Alchemy API. The rest will be ignored.');
  }
  final options = BaseOptions(
    method: 'GET',
    headers: {'accept': 'application/json'},
  );

  final dio = Dio(options);
  final List ownedNfts = [];
  var pageKey;
  try {
    while (true) {
      var response = await dio.get(
        '${chainConfig[chainId]!.alchemyBaseUrl}nft/v3/${dotenv.get('ALCHEMY_API_KEY')}/getNFTsForOwner',
        queryParameters: {
          'owner': owner.hex,
          'withMetadata': 'true',
          'pageSize': '100',
          'excludeFilters[]': ['SPAM', 'AIRDROPS'],
          'pageKey': pageKey,
          'contractAddresses[]': contractAddresses != null
              ? contractAddresses.map((e) => e.hex).toList()
              : [],
        },
      );

      ownedNfts.addAll(response.data['ownedNfts']);

      // Check if there's a new pageKey and update it, otherwise break the loop
      if (response.data['pageKey'] != null) {
        pageKey = response.data['pageKey'];
      } else {
        break;
      }
    }
    return ownedNfts;
  } catch (err) {
    print(err);
    rethrow;
  }
}

Future<List<AlchemyNftTokenIdCollectionChainId>> fetchMintedOcNftsByAddress(
    EthereumAddress userAddress, int chainId,
    {List<EthereumAddress>? contractAddresses}) async {
  final options = BaseOptions(
    method: 'POST',
    headers: {'accept': 'application/json', 'content-type': 'application/json'},
  );

  final dio = Dio(options);
  final List mintTransferEvents = [];
  var pageKey;
  List<String> uniqueTokenIds = [];
  var params = {
    "fromBlock": "0x0",
    "fromAddress": "0x0000000000000000000000000000000000000000",
    "toAddress": userAddress.hex,
    "category": ["erc721", "erc1155"],
    "contractAddresses": contractAddresses != null
        ? contractAddresses.map((e) => e.hex).toList()
        : [],
  };
  try {
    while (true) {
      var response = await dio.post(
        '${chainConfig[chainId]!.alchemyBaseUrl}v2/${dotenv.get('ALCHEMY_API_KEY')}',
        data: {
          "id": 1,
          "jsonrpc": "2.0",
          "method": "alchemy_getAssetTransfers",
          "params": [
            pageKey == null ? params : {"pageKey": pageKey, ...params}
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

      // Check if there's a new pageKey and update it, otherwise break the loop
      if (response.data['pageKey'] != null) {
        pageKey = response.data['pageKey'];
      } else {
        break;
      }
    }

    //minte
    List<AlchemyNftTokenIdCollectionChainId> mintedNftEvents =
        mintTransferEvents.map((e) {
      return AlchemyNftTokenIdCollectionChainId(
        chainId: 137, //TODO: make dynamic
        nftTokenId: e['tokenId'],
        collectionAddress: e['rawContract']['address'],
      );
    }).toList();

    List<AlchemyNftTokenIdCollectionChainId> uniqueMintedNftEvents = [];

    //loop over unique token ids
    for (var i = 0; i < uniqueTokenIds.length; i++) {
      final lastMintEvent = mintedNftEvents.lastWhere(
          (element) => element.nftTokenId == uniqueTokenIds[i],
          orElse: () => AlchemyNftTokenIdCollectionChainId(
              chainId: 137, //TODO: make dynamic
              nftTokenId: '',
              collectionAddress: ''));
      if (lastMintEvent.nftTokenId != '') {
        uniqueMintedNftEvents.add(lastMintEvent);
      }
    }

    return uniqueMintedNftEvents;
  } catch (err) {
    print(err);
    rethrow;
  }
}

Future<List> getNotBurnedMintedOcNftsByAddress(
    EthereumAddress userAddress, int chainId,
    {List<EthereumAddress>? contractAddresses}) async {
  final options = BaseOptions(
    method: 'GET',
    headers: {
      'accept': 'application/json',
    },
  );

  final dio = Dio(options);
  final List<AlchemyNftTokenIdCollectionChainId> mintedNfts =
      await fetchMintedOcNftsByAddress(userAddress, chainId,
          contractAddresses: contractAddresses);

  List<Future> futures = [];

  for (var nft in mintedNfts) {
    //TODO: I think this only works for a max of 45 NFTs before Error code 429 too many requests from Alchemy
    futures.add(dio.get(
      '${chainConfig[chainId]!.alchemyBaseUrl}nft/v3/${dotenv.get('ALCHEMY_API_KEY')}/getOwnersForNFT',
      queryParameters: {
        "contractAddress": nft.collectionAddress,
        "tokenId": nft.nftTokenId
      },
    ));
  }
  List filteredNfts = [];
  var responses = await Future.wait(futures);
  for (var i = 0; i < responses.length; i++) {
    if (responses[i]
        .data['owners']
        .contains('0x0000000000000000000000000000000000000000')) {
      continue;
    }

    filteredNfts.add(mintedNfts[i]);
  }

  return filteredNfts;
}

//TODO:
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
    '${chainConfig[chainId]!.alchemyBaseUrl}nft/v3/${dotenv.get('ALCHEMY_API_KEY')}/getNFTMetadataBatch',
    data: {"tokens": tokens.toList()},
  );

  return response.data;
}
