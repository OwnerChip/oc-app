import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChipInfo extends StatelessWidget {
  const ChipInfo(
      {super.key,
      required this.tokenId,
      required this.chipName,
      required this.walletAddress});

  final BigInt? tokenId;
  final String chipName;
  final String walletAddress;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            Text('Chip Name: ', style: Theme.of(context).textTheme.headline5),
            Text(chipName, style: Theme.of(context).textTheme.bodyText2)
          ],
        ),
        const SizedBox(height: 5),
        tokenId != null
            ? Row(
                children: [
                  Text('Token ID: ',
                      style: Theme.of(context).textTheme.headline5),
                  Text('${tokenId.toString().substring(0, 5)}...',
                      style: Theme.of(context).textTheme.bodyText2),
                  IconButton(
                      color: Theme.of(context).primaryColor,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                      iconSize: 25,
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: tokenId.toString()));
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Token ID copied to clipboard')));
                      },
                      icon: const Icon(Icons.copy))
                ],
              )
            : Container(),
        const SizedBox(height: 5),
        Row(
          children: [
            Text('Chip Wallet: ', style: Theme.of(context).textTheme.headline5),
            Text('${walletAddress.substring(0, 5)}...',
                style: Theme.of(context).textTheme.bodyText2),
            //icon that copies navargs.nftowner to clipboard
            IconButton(
                color: Theme.of(context).primaryColor,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
                iconSize: 25,
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
