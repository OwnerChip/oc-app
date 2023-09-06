//import packages

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:ownerchip_whitelabel/services/scan.services.dart';
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
  EthereumAddress? chipAddress1;
  EthereumAddress? chipAddress2;
  List<EthereumAddress> allChipAddresses = [];

  void setChipAddresses(chipAddress1, chipAddress2) {
    setState(() {
      this.chipAddress1 = chipAddress1;
      this.chipAddress2 = chipAddress2;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        text: 'Init second card slot',
        showBackButton: true,
      ),
      body: ScreenBodyLayout(
        withScrollView: true,
        children: [
          CustomRoundedButton(
            text: 'Init second card slot',
            onPressed: () async {
              try {
                setState(() {
                  allChipAddresses = [];
                });
                await ownerCardAdminInit(context, ref, setChipAddresses);
                ScaffoldMessenger.of(context).showSnackBar(returnSnackBarWidget(
                    context.loc.successHeadingSnackbar,
                    'First two key slots created.',
                    'success'));
              } catch (e) {
                NfcManager.instance.stopSession();
                ScaffoldMessenger.of(context).showSnackBar(returnSnackBarWidget(
                    context.loc.errorHeadingSnackBar,
                    'Error writing/reading first two key slots.',
                    'error'));
              }
            },
          ),
          SizedBox(height: 20),
          CustomRoundedButton(
            text: 'List all chip addresses',
            onPressed: () async {
              try {
                setState(() {
                  chipAddress1 = null;
                  chipAddress2 = null;
                });
                List<EthereumAddress> result =
                    await getAllChipWalletAddresses(context, ref);
                setState(() {
                  allChipAddresses = result;
                });
              } catch (e) {}
            },
          ),
          SizedBox(
            height: 30,
          ),
          //if chip addresses are not null display them
          chipAddress1 != null
              ? Column(
                  children: [
                    Text('Chip address 1: '),
                    Text('${chipAddress1!.hex}'),
                    IconButton(
                        color: Theme.of(context).primaryColor,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        iconSize: 25,
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: chipAddress1.toString()));
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Chip address 1 copied to clipboard')));
                        },
                        icon: const Icon(Icons.copy)),
                    SizedBox(
                      height: 50,
                    ),
                  ],
                )
              : Container(),

          chipAddress2 != null
              ? Column(
                  children: [
                    Text('Chip address 2: '),
                    Text('${chipAddress2!.hex}'),
                    IconButton(
                        color: Theme.of(context).primaryColor,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        iconSize: 25,
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: chipAddress2.toString()));
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Chip address 2 copied to clipboard')));
                        },
                        icon: const Icon(Icons.copy)),
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
