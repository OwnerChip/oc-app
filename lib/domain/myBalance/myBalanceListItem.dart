import 'dart:math';

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

  // convert wei to ether
  double get balanceInEther => balance / BigInt.from(pow(10, decimals));

  String get balanceInEtherString {
    String str = balanceInEther.toStringAsFixed(decimals);

    // max 6 decimal places
    if (str.split(".")[1].length > 6) {
      str = "${str.split(".")[0]}.${str.split(".")[1].substring(0, 6)}";
    }

    // remove trailing zeros
    str = str.replaceAll(RegExp(r"([.]*0+)(?!.*\d)"), "");

    // ensure at least two decimal places
    if (!str.contains(".")) {
      str += ".00";
    } else if (str.split(".")[1].length == 1) {
      str += "0";
    }


    return str;
  }

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
