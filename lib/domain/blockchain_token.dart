import 'package:flutter/material.dart';
import 'package:web3dart/web3dart.dart';
import 'package:flutter/services.dart' show rootBundle;

class BlockchainToken {
  final String symbol;
  final String abiAssetPath;
  final EthereumAddress contractAddress;

  final String iconPath;

  final int decimals;

  BlockchainToken({
    required this.symbol,
    required this.abiAssetPath,
    required this.contractAddress,
    required this.iconPath,
    this.decimals = 18,
  });

  DeployedContract? _deployedContract;

  Future<DeployedContract> getDeployedContract() async {
    _deployedContract ??= DeployedContract(
      ContractAbi.fromJson(
        await rootBundle.loadString(abiAssetPath),
        symbol,
      ),
      contractAddress,
    );

    return _deployedContract!;
  }
}
