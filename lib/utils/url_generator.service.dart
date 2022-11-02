import 'package:flutter_dotenv/flutter_dotenv.dart';

Uri generateBlockchainExplorerTokenDetailsUrl(String tokenId) {
  final String baseUrl = dotenv.get('CHAIN_EXPLORER_URL');
  final String contractAddress = dotenv.get('CONTRACT_ADDRESS');
  final String res = "${baseUrl}token/${contractAddress}?a=${tokenId}";
  return Uri.parse(res);
}

Uri generateOpenSeaTokenDetailsUrl(String tokenId) {
  final String baseUrl = dotenv.get('OPENSEA_URL');
  final String contractAddress = dotenv.get('CONTRACT_ADDRESS');
  final String res = "${baseUrl}${contractAddress}/${tokenId}";
  return Uri.parse(res);
}

Uri generateLandingPageUrl() {
  final String baseUrl = dotenv.get('LANDING_PAGE_URL');
  return Uri.parse(baseUrl);
}
