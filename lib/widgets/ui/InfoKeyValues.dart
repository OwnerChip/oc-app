import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:ownerchip_whitelabel/services/backend/backend.services.dart';
import 'package:url_launcher/url_launcher.dart';

class InfoKeyValues extends StatelessWidget {
  InfoKeyValues(
      {super.key,
      required this.keys,
      required this.values,
      this.keyWidth = 135,
      this.valueWidth = 135});

  final List<String> keys;
  final List<dynamic> values;
  final double keyWidth;
  final double valueWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                          child: Text('${val.trim()}: ',
                              style: Theme.of(context).textTheme.bodyMedium),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Flexible(
                      child: values[idx] is String
                          ? Linkify(
                              style:
                                  Theme.of(context).textTheme.headlineSmall,
                              onOpen: (link) async {
                                if (!await launchUrl(Uri.parse(link.url))) {
                                  throw Exception(
                                      'Could not launch ${link.url}');
                                }
                              },
                              text: values[idx].toString().trim(),
                            )
                          : values[idx])
                ],
              ),
              const SizedBox(height: 5)
            ],
          );
        }).toList()
      ]),
    );
  }
}
