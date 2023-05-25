import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/config/chains.dart';
import 'package:ownerchip_whitelabel/config/collections.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/services/providers.service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';

//stateless riverpod widget ConsumerWidget
class ChainDropdown extends ConsumerWidget {
  const ChainDropdown({super.key});

  _buildDropdown(data, ref) {
    return DropdownButton<int>(
        isExpanded: true,
        dropdownColor: CustomColors(dotenv.get('APP_ID')).cardColor,
        style: TextStyle(
            color: CustomColors(dotenv.get('APP_ID')).chainDropdownTextColor),
        // value: chainId,
        value: ref.read(selectedChainIdProvider(data)),
        onChanged: (value) {
          ref.read(selectedChainIdProvider(data).notifier).state = value!;
        },
        items: data.collections.keys.map<DropdownMenuItem<int>>((int key) {
          print('test');
          return DropdownMenuItem(
            value: key,
            child: Text(chainConfig[key]!.networkName),
          );
        }).toList());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AsyncValue<BlockchainCollectionList> relevantCollections =
        ref.watch(findAllMinterRolesProvider);

    return relevantCollections.when(
        data: (data) => _buildDropdown(data, ref),
        loading: () => const Text("Loading..."),
        error: (err, stack) => const Text("Error"));
  }
}
