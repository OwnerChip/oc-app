//import packages

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/services/nfc.services.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
//import widgets
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/InfoKeyValues.dart';
import 'package:ownerchip_whitelabel/widgets/ui/appBar/CustomAppBar.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:web3dart/credentials.dart';

class AdminInitCard extends ConsumerStatefulWidget {
  const AdminInitCard({Key? key}) : super(key: key);

  static const routeName = '/adminInitCard';

  @override
  _AdminInitCard createState() => _AdminInitCard();
}

class _AdminInitCard extends ConsumerState<AdminInitCard> {
  final _formKey = GlobalKey<FormState>();
  EthereumAddress? chipAddress0;
  List<EthereumAddress> allChipAddresses = [];
  String customerId = '';

  void setChipAddressZero(EthereumAddress chipAddress0) {
    setState(() {
      this.chipAddress0 = chipAddress0;
    });
  }

  @override
  Widget build(BuildContext context) {
    String baseId = dotenv.get('OWNERCARD_BASE_ID');
    Map<String, EthereumAddress> slot0Addresses = {
      'OwnerChip':
          EthereumAddress.fromHex('0x3e873dd1a384860640dff4a78b80f95907ccc3c5'),
      'Stebo':
          EthereumAddress.fromHex('0xdb166d2468d111bba8f80904cfd8143cebd07507'),
      'Infineon':
          EthereumAddress.fromHex('0x3ad219eb491f5587bc26738cc9abd842f57e188f'),
      'Stilami':
          EthereumAddress.fromHex('0x9eb5ac7ce359f50176f98a4b6b6bdbca0cd79185')
    };
    List<String> keys = ['OwnerChip', 'Stebo', 'Infineon', 'Stilami'];
    List values = [
      'ID: 100 \nSlot 0:${slot0Addresses['OwnerChip']!.hex.substring(0, 6)}...',
      'ID: 101 \nSlot 0: ${slot0Addresses['Stebo']!.hex.substring(0, 6)}...',
      'ID: 102 \nSlot 0: ${slot0Addresses['Infineon']!.hex.substring(0, 6)}...',
      'ID:103 \nSlot 0: ${slot0Addresses['Stilami']!.hex.substring(0, 6)}...'
    ];
    return Scaffold(
      appBar: const CustomAppBar(
        text: 'Init OwnerCards slot',
        showBackButton: true,
      ),
      body: ScreenBodyLayout(
        withScrollView: true,
        children: [
          const Text(
              'ATTENTION: Key slot 0 can only be set on OwnerCards that are not yet PIN code locked. '),
          const SizedBox(height: 10),
          InfoKeyValues(keys: keys, values: values),
          const SizedBox(height: 20),
          //text input field for the customer id
          Form(
            key: _formKey,
            child: TextFormField(
              style: Theme.of(context).textTheme.bodyMedium,
              cursorColor:
                  CustomColors(dotenv.get('APP_ID').toString()).accentColor,
              decoration: InputDecoration(
                labelText: 'Customer ID',
                labelStyle: Theme.of(context).textTheme.bodyMedium,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color: CustomColors(dotenv.get('APP_ID').toString())
                          .primaryColor,
                      width: 2.0), // normal border color
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color: CustomColors(dotenv.get('APP_ID').toString())
                          .primaryColor,
                      width: 2.0), // focused border color
                ),
              ),
              keyboardType: TextInputType.text,
              obscureText: false,
              onChanged: (value) {
                setState(() {
                  customerId = value;
                });
              },
              validator: (value) {
                //check if value can be converted to integer
                try {
                  int.parse(value!);
                } catch (e) {
                  return 'Customer ID must be integer';
                }
                if (int.parse(value) < 100) {
                  return 'Customer ID cannot be smaller than 100';
                }
                if (value == null || value.isEmpty) {
                  return 'Please enter a customer id';
                }
                return null;
              },
            ),
          ),

          const SizedBox(height: 20),
          CustomRoundedButton(
            text: 'Init OwnerCard slot 0',
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                setState(() {
                  allChipAddresses = [];
                });
                await importKeyToSlotZero(
                    context, ref, setChipAddressZero, customerId);
              }
            },
          ),
          const SizedBox(height: 20),
          CustomRoundedButton(
            text: 'List all chip addresses',
            onPressed: () async {
              setState(() {
                chipAddress0 = null;
              });
              List<EthereumAddress> result =
                  await getAllChipWalletAddresses(context, ref);
              setState(() {
                allChipAddresses = result;
              });
            },
          ),
          const SizedBox(
            height: 30,
          ),
          //if chip addresses are not null display them
          chipAddress0 != null
              ? Column(
                  children: [
                    Text('Chip address 0: '),
                    Text('${chipAddress0!.hex}'),
                    IconButton(
                        color: Theme.of(context).primaryColor,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        iconSize: 25,
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: chipAddress0.toString()));
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Chip address 0 copied to clipboard')));
                        },
                        icon: const Icon(Icons.copy)),
                    SizedBox(
                      height: 50,
                    ),
                  ],
                )
              : Container(),

          allChipAddresses.isNotEmpty
              ? Column(
                  children: [
                    Text('Number of addresses: ${allChipAddresses.length}'),
                    Text('All chip addresses: '),
                    ...allChipAddresses
                        .asMap()
                        .map((index, address) {
                          return MapEntry(
                            index,
                            Column(
                              children: [
                                Wrap(
                                  children: [
                                    Text('Key ${index}: ${address.hex}'),
                                    IconButton(
                                        color: Theme.of(context).primaryColor,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        iconSize: 25,
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(
                                              text: allChipAddresses[index]
                                                  .toString()));
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                                  content: Text(
                                                      'Chip address copied to clipboard')));
                                        },
                                        icon: const Icon(Icons.copy))
                                  ],
                                ), // show the index before the address
                                SizedBox(height: 40.0), // add 10px spacing
                              ],
                            ),
                          );
                        })
                        .values
                        .toList(),
                  ],
                )
              : Container(),
        ],
      ),
    );
  }
}
