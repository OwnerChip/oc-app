import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/config/chains.dart';
import 'package:ownerchip_whitelabel/config/collections.dart';
import 'package:ownerchip_whitelabel/services/providers.service.dart';

//stateless riverpod widget ConsumerWidget
class CollectionDropdown extends ConsumerWidget {
  const CollectionDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionId = ref.watch(selectedCollectionIdProvider);
    final chainId = ref.watch(selectedChainIdProvider);
    return DropdownButton<String>(
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
        }).toList()
        // [
        //   DropdownMenuItem(
        //     value: '0x6fe0Fd3f6430DcFF517Cd939815Fab115B033679',
        //     child: Text('0x6fe0Fd3f6430DcFF517Cd939...'),
        //   )
        // ]

        );
  }
}
