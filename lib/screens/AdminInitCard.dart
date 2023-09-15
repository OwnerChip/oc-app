//import packages

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:ownerchip_whitelabel/services/scan.services.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';

//import widgets
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomAppBar.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:web3dart/credentials.dart';

class AdminInitCard extends ConsumerStatefulWidget {
  const AdminInitCard({Key? key}) : super(key: key);

  static const routeName = '/adminInitCard';

  @override
  _AdminInitCard createState() => _AdminInitCard();
}

class _AdminInitCard extends ConsumerState<AdminInitCard> {
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
          const Text('OwnerChip: 100'),
          const Text('Stebo: 101'),
          const Text('Infineon: 102'),
          const Text('Stilami: 103'),
          const SizedBox(height: 20),
          //text input field for the customer id
          TextFormField(
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
          ),
          const SizedBox(height: 20),
          CustomRoundedButton(
            text: 'Init OwnerCard slot 0',
            onPressed: () async {
              setState(() {
                allChipAddresses = [];
              });
              await importKeyToSlotZero(
                  context, ref, setChipAddressZero, customerId);
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
                    for (var address in allChipAddresses)
                      Column(
                        children: [
                          Text(
                              '${address.hex}'), // show the index before the address
                          SizedBox(height: 15.0), // add 10px spacing
                        ],
                      )
                  ],
                )
              : Container(),
        ],
      ),
    );
  }
}
