import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:web3dart/web3dart.dart';

class DisplayLongStringWithCopy extends StatelessWidget {
  const DisplayLongStringWithCopy({
    super.key,
    required this.string,
    this.iconSize = 25,
    this.textCopiedMessage = 'Copied!',
    this.textStyles,
    this.maxLength = 8,
  });

  final String string;
  final double iconSize;
  final TextStyle? textStyles;
  final String textCopiedMessage;

  final int maxLength;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        Text('${string.substring(0, maxLength)}...',
            style: textStyles ?? Theme.of(context).textTheme.headlineSmall),
        const SizedBox(
          width: 8,
        ),
        InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: string));
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(textCopiedMessage)));
            },
            child: Icon(
              Icons.copy,
              color: Theme.of(context).primaryColor,
              size: iconSize,
            ))
      ],
    );
  }
}
