import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/config/collections.dart';
import 'package:ownerchip_whitelabel/services/providers.service.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:web3dart/web3dart.dart';

//stateless riverpod widget ConsumerWidget
class CollectionDropdown extends ConsumerWidget {
  const CollectionDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final EthereumAddress collectionId =
        ref.watch(selectedCollectionIdProvider);
    final int chainId = ref.watch(selectedChainIdProvider);
    return DropdownButton<dynamic>(
        dropdownColor: CustomColors(dotenv.get('APP_ID')).cardColor,
        style: TextStyle(
            color: CustomColors(dotenv.get('APP_ID')).chainDropdownTextColor),
        value: collectionId,
        onChanged: (value) {
          ref.read(selectedCollectionIdProvider.notifier).state = value!;
        },
        items: Collections(dotenv.env['APP_ID']!)
            .collections[chainId]!
            .map((collection) {
          return DropdownMenuItem(
            value: collection['id'],
            child: Text(collection['name']!),
          );
        }).toList());
  }
}
