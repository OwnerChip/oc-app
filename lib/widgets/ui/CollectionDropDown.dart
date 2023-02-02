import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/config/chains.dart';
import 'package:ownerchip_whitelabel/services/providers.service.dart';

//stateless riverpod widget ConsumerWidget
class ChainDropdown extends ConsumerWidget {
  const ChainDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DropdownButton<int>(
        // value: chainId,
        value: ref.watch(chainIdProvider),
        onChanged: (value) {
          ref.read(chainIdProvider.notifier).state = value!;
        },
        items: chainConfig.keys.map((key) {
          return DropdownMenuItem(
            value: key,
            child: Text(chainConfig[key]!.networkName),
          );
        }).toList());
  }
}
