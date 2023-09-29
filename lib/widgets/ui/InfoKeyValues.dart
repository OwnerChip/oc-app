import 'package:flutter/material.dart';

class InfoKeyValues extends StatelessWidget {
  InfoKeyValues(
      {super.key,
      required this.keys,
      required this.values,
      this.keyWidth = 135,
      this.valueWidth = 135});

  final List<String> keys;
  final List<String> values;
  final double keyWidth;
  final double valueWidth;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ...keys.asMap().entries.map((entry) {
        int idx = entry.key;
        String val = entry.value;

        return Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: keyWidth,
                  child: Flex(
                    direction: Axis.horizontal,
                    children: [
                      Flexible(
                        child: Text('$val: ',
                            style: Theme.of(context).textTheme.bodyMedium),
                      )
                    ],
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                SizedBox(
                  width: valueWidth,
                  child: Flex(
                    direction: Axis.horizontal,
                    children: [
                      Flexible(
                          child: Text(values[idx].toString(),
                              style: Theme.of(context).textTheme.headlineSmall))
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 5)
          ],
        );
      }).toList()
    ]);
  }
}
