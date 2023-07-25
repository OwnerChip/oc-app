import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/config/chains.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/services/providers.services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';

//stateless riverpod widget ConsumerWidget
class ChainDropdown extends ConsumerWidget {
  const ChainDropdown({super.key});

  _buildDropdown(data, ref, String selectString) {
    return DropdownButton<int>(
        hint: Text(
          selectString,
          style: TextStyle(
              color: CustomColors(dotenv.get('APP_ID')).chainDropdownTextColor),
        ),
        isExpanded: true,
        dropdownColor: CustomColors(dotenv.get('APP_ID')).cardColor,
        style: TextStyle(
            color: CustomColors(dotenv.get('APP_ID')).chainDropdownTextColor),
        value: ref.watch(selectedChainIdProvider),
        onChanged: (value) {
          ref.read(selectedChainIdProvider.notifier).state = value;
        },
        items: data.collections.keys.map<DropdownMenuItem<int>>((int key) {
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
        data: (data) => _buildDropdown(data, ref, context.loc.pleaseSelect),
        loading: () => const SizedBox(
            height: 50,
            width: double.infinity,
            child: Align(
                alignment: Alignment.centerLeft, child: Text("Loading..."))),
        error: (err, stack) => const Text("Error"));
  }
}
