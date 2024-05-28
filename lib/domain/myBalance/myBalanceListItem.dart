class MyBalanceListItem {
  final String name;
  final int chain;
  final BigInt balance;
  final double balanceEur;

  final String iconPath;

  double get balanceInEther => balance / BigInt.from(10).pow(18);

  const MyBalanceListItem({
    required this.name,
    required this.chain,
    required this.balance,
    required this.balanceEur,
    required this.iconPath,
  });
}
