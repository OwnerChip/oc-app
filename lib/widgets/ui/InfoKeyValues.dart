import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web3dart/web3dart.dart';

class InfoKeyValues extends StatelessWidget {
  const InfoKeyValues({super.key, required this.keys, required this.values});

  final List<String> keys;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ...keys.asMap().entries.map((entry) {
        int idx = entry.key;
        String val = entry.value;

        return Row(
          children: [
            Text('$val: ', style: Theme.of(context).textTheme.bodyText2),
            Text(values[idx].toString(),
                style: Theme.of(context).textTheme.headline5)
          ],
        );
      }).toList()
    ]);
  }
}
