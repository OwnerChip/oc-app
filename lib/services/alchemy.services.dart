import 'package:dio/dio.dart';
import 'package:web3dart/web3dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/config/chains.dart';

// A function that fetches NFTs for a given owner address and chainId
Future<Map> fetchNFTsForOwner(EthereumAddress owner, int chainId) async {
  final options = BaseOptions(
    method: 'GET',
    headers: {'accept': 'application/json'},
  );

  final dio = Dio(options);

  try {
    var response = await dio.get(
      '${chainConfig[chainId]!.alchemyBaseUrl}nft/v3/${dotenv.get('ALCHEMY_API_KEY')}/getNFTsForOwner',
      queryParameters: {
        'owner': owner.hex,
        'withMetadata': 'true',
        'pageSize': '100'
      },
    );
    return response.data;
  } catch (err) {
    print(err);
    rethrow;
  }
}
