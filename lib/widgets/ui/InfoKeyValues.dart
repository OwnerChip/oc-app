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

        return Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 135,
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
                  width: 135,
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
