import 'package:web3dart/web3dart.dart';

class Collection {
  final EthereumAddress id;
  final String name;
  final EthereumAddress? voucherAddress;
  final String? symbol;
  final int? chainId;
  bool? hasMinterRole;

  Collection(this.id, this.name,
      {this.voucherAddress, this.symbol, this.chainId, this.hasMinterRole});
}
