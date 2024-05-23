import 'package:flutter/material.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/widgets/ui/DisplayLongStringWithCopy.dart';
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
                    style: Theme.of(context).textTheme.bodyMedium),
                Text(chipName!,
                    style: Theme.of(context).textTheme.headlineSmall)
              ],
            )
          : Container(),
      const SizedBox(height: 5),
      tokenId != null
          ? Row(
              //space between
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Token ID: ',
                    style: Theme.of(context).textTheme.bodyMedium),
                Container(
                  width: 150,
                  child: DisplayLongStringWithCopy(
                    string: tokenId.toString(),
                    textStyles: Theme.of(context).textTheme.headlineSmall,
                  ),
                )
              ],
            )
          : Container(),
      const SizedBox(height: 5),
      walletAddress != null
          ? Row(
              children: [
                Text('Wallet: ', style: Theme.of(context).textTheme.bodyMedium),
                DisplayLongStringWithCopy(
                  textCopiedMessage: context.loc.tokenIdCopiedToClipboard,
                  string: walletAddress.toString(),
                  textStyles: Theme.of(context).textTheme.headlineSmall,
                )
              ],
            )
          : Container(),
    ]);
  }
}
