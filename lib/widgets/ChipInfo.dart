import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChipInfo extends StatelessWidget {
  const ChipInfo(
      {super.key,
      required this.tokenId,
      required this.chipName,
      required this.walletAddress});

  final BigInt? tokenId;
  final String? chipName;
  final String walletAddress;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Chip Name: $chipName'),
        const SizedBox(height: 5),
        Row(
          children: [
            Text('Token ID: ${tokenId.toString().substring(0, 5)}...',
                style: const TextStyle(fontSize: 14)),
            //icon that copies navargs.nftowner to clipboard
            IconButton(
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
                iconSize: 20,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: tokenId.toString()));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Token ID copied to clipboard')));
                },
                icon: const Icon(Icons.copy))
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Text('Chip Wallet: ${walletAddress.substring(0, 5)}...',
                style: const TextStyle(fontSize: 14)),
            //icon that copies navargs.nftowner to clipboard
            IconButton(
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
                iconSize: 20,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: walletAddress));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content:
                          Text('Chip wallet address copied to clipboard')));
                },
                icon: const Icon(Icons.copy))
          ],
        ),
      ]),
    );
  }
}
