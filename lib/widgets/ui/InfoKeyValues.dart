import 'package:flutter/material.dart';

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
          //space between
          mainAxisAlignment: MainAxisAlignment.spaceBetween,

          children: [
            Text('$val: ', style: Theme.of(context).textTheme.bodyMedium),
            Container(
              width: 150,
              child: Flexible(
                  child: Text(values[idx].toString(),
                      style: Theme.of(context).textTheme.headlineSmall)),
            )
          ],
        );
      }).toList()
    ]);
  }
}
