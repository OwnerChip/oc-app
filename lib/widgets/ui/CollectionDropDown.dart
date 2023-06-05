import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/services/providers.service.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';

//stateless riverpod widget ConsumerWidget
class CollectionDropdown extends ConsumerWidget {
  const CollectionDropdown({super.key});

  _buildDropdown(BlockchainCollectionList data, ref, selectString) {
    final Collection? collection = ref.watch(selectedCollectionIdProvider);
    final int? chainId = ref.watch(selectedChainIdProvider);

    return DropdownButton<dynamic>(
        hint: Text(
          selectString,
          style: TextStyle(
              color: CustomColors(dotenv.get('APP_ID')).chainDropdownTextColor),
        ),
        isExpanded: true,
        dropdownColor: CustomColors(dotenv.get('APP_ID')).cardColor,
        style: TextStyle(
            color: CustomColors(dotenv.get('APP_ID')).chainDropdownTextColor),
        value: collection,
        onChanged: (value) {
          ref.read(selectedCollectionIdProvider.notifier).state = value;
        },
        items: chainId == null
            ? []
            : data.collections[chainId]!.map<DropdownMenuItem>((collection) {
                return DropdownMenuItem(
                  value: collection,
                  child: Text(collection.name),
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
