import 'package:ownerchip_whitelabel/config/chains.dart';
import 'package:web3dart/web3dart.dart';

// part 'rariblePayout.g.dart';

// @JsonSerializable(explicitToJson: true)
class RariblePayout {
  final EthereumAddress account;
  final int value; // in bps (100=1%)

  final int chainId;

  RariblePayout({
    required this.account,
    required this.value,
    required this.chainId,
  });

  Map<String, dynamic> toJson() {
    final chain = chainConfig[chainId]!;
    return {
      'account': "ETHEREUM:${account.hex}",
      'value': value,
    };
  }

  Map<String, dynamic> toJsonDeprecated() {
    return {
      'account': account.hex,
      'value': value,
    };
  }
}
