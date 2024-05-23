import 'package:web3dart/web3dart.dart';

class TokenChainAndCollection {
  final int chainId;
  final EthereumAddress collectionId;
  final BigInt tokenId;

  TokenChainAndCollection(this.chainId, this.collectionId, this.tokenId);
}
