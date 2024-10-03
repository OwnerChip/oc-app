import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:ownerchip_whitelabel/services/backend/backend.services.dart';
import 'package:url_launcher/url_launcher.dart';

class InfoKeyValues extends StatelessWidget {
  const InfoKeyValues({
    super.key,
    required this.keys,
    required this.values,
  });

  final List<String> keys;
  final List<dynamic> values;

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
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    flex: 1,
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
                    width: 4,
                  ),
                  Flexible(
                      flex: 1,
                      child: values[idx] is String
                          ? Linkify(
                              style: Theme.of(context).textTheme.headlineSmall,
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
