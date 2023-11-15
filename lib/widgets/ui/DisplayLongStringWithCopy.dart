import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:web3dart/web3dart.dart';

class DisplayLongStringWithCopy extends StatelessWidget {
  const DisplayLongStringWithCopy(
      {super.key,
      required this.string,
      this.iconSize = 25,
      this.textCopiedMessage = 'Copied!',
      this.textStyles});

  final String string;
  final double iconSize;
  final TextStyle? textStyles;
  final String textCopiedMessage;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('${string.substring(0, 8)}...',
            style: textStyles ?? Theme.of(context).textTheme.headlineSmall),
        IconButton(
            color: Theme.of(context).primaryColor,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            iconSize: iconSize,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: string));
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(textCopiedMessage)));
            },
            icon: const Icon(Icons.copy))
      ],
    );
  }
}
