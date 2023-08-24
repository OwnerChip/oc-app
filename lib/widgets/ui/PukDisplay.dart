import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PukDisplay extends StatelessWidget {
  PukDisplay({super.key, required this.puk});

  String puk;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text('Save your PUK'),
      Text('You can use this code in case you forget your PIN code.'),
      Text('PUK: $puk', style: Theme.of(context).textTheme.headlineSmall),
      IconButton(
          color: Theme.of(context).primaryColor,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          iconSize: 25,
          onPressed: () {
            Clipboard.setData(ClipboardData(text: puk));
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PUK copied to clipboard')));
          },
          icon: const Icon(Icons.copy))
    ]);
  }
}
