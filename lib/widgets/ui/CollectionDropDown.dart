import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/config/collections.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/services/providers.service.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:web3dart/web3dart.dart';

//stateless riverpod widget ConsumerWidget
class CollectionDropdown extends ConsumerWidget {
  const CollectionDropdown({super.key});

  _buildDropdown(BlockchainCollectionList data, ref) {
    final Collection collection = ref.read(selectedCollectionIdProvider(data));
    final int chainId = ref.watch(selectedChainIdProvider(data));

    return DropdownButton<dynamic>(
        dropdownColor: CustomColors(dotenv.get('APP_ID')).cardColor,
        style: TextStyle(
            color: CustomColors(dotenv.get('APP_ID')).chainDropdownTextColor),
        value: collection.id,
        onChanged: (value) {
          ref.read(selectedCollectionIdProvider(data).notifier).state = value!;
        },
        items: data.collections[chainId]!.map<DropdownMenuItem>((collection) {
          return DropdownMenuItem(
            value: collection.id,
            child: Text(collection.name),
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
