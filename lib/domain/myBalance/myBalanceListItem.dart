import 'package:ownerchip_whitelabel/domain/blockchain_token.dart';
import 'package:web3dart/web3dart.dart';

class MyBalanceListItem {
  final String name;
  final String symbol;
  final int chain;
  final BigInt balance;
  final double balanceEur;
  final String iconPath;
  final int decimals;
  final int? token;

  double get balanceInEther => balance / BigInt.from(10).pow(decimals);

  const MyBalanceListItem({
    required this.name,
    required this.chain,
    required this.symbol,
    required this.balance,
    required this.balanceEur,
    required this.iconPath,
    this.decimals = 18,
    this.token,
  });
}
