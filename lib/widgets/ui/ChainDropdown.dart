import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/config/chains.dart';
import 'package:ownerchip_whitelabel/config/collections.dart';
import 'package:ownerchip_whitelabel/services/providers.service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

//stateless riverpod widget ConsumerWidget
class ChainDropdown extends ConsumerWidget {
  const ChainDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DropdownButton<int>(
        // value: chainId,
        value: ref.watch(selectedChainIdProvider),
        onChanged: (value) {
          ref.read(selectedChainIdProvider.notifier).state = value!;
        },
        items: Collections(dotenv.env['APP_ID']!).collections.keys.map((key) {
          return DropdownMenuItem(
            value: key,
            child: Text(chainConfig[key]!.networkName),
          );
        }).toList());
  }
}
