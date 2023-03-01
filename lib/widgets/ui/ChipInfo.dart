import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web3dart/web3dart.dart';

class ChipInfo extends StatelessWidget {
  const ChipInfo({super.key, this.tokenId, this.chipName, this.walletAddress});

  final BigInt? tokenId;
  final String? chipName;
  final EthereumAddress? walletAddress;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      chipName != null
          ? Row(
              children: [
                Text('Chip Name: ',
                    style: Theme.of(context).textTheme.headlineSmall),
                Text(chipName!, style: Theme.of(context).textTheme.bodyMedium)
              ],
            )
          : Container(),
      const SizedBox(height: 5),
      tokenId != null
          ? Row(
              children: [
                Text('Token ID: ',
                    style: Theme.of(context).textTheme.headlineSmall),
                Text('${tokenId.toString().substring(0, 8)}...',
                    style: Theme.of(context).textTheme.bodyMedium),
                IconButton(
                    color: Theme.of(context).primaryColor,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    iconSize: 25,
                    onPressed: () {
                      Clipboard.setData(
                          ClipboardData(text: tokenId.toString()));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Token ID copied to clipboard')));
                    },
                    icon: const Icon(Icons.copy))
              ],
            )
          : Container(),
      const SizedBox(height: 5),
      walletAddress != null
          ? Row(
              children: [
                Text('Wallet: ',
                    style: Theme.of(context).textTheme.headlineSmall),
                Text('${walletAddress!.toString().substring(0, 8)}...',
                    style: Theme.of(context).textTheme.bodyMedium),
                //icon that copies navargs.nftowner to clipboard
                IconButton(
                    color: Theme.of(context).primaryColor,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    iconSize: 25,
                    onPressed: () {
                      Clipboard.setData(
                          ClipboardData(text: walletAddress.toString()));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Wallet address copied to clipboard')));
                    },
                    icon: const Icon(Icons.copy))
              ],
            )
          : Container(),
    ]);
  }
}
