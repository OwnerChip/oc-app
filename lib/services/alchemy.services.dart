import 'package:dio/dio.dart';
import 'package:web3dart/web3dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/config/chains.dart';

// A function that fetches NFTs for a given owner address and chainId
Future<List> fetchNFTsForOwner(EthereumAddress owner, int chainId,
    {String? pageKey, List<EthereumAddress>? contractAddresses}) async {
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
              : '',
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
