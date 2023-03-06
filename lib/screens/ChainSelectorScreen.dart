//import packages
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';

//import widgets
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';
import 'package:ownerchip_whitelabel/widgets/ui/ChainDropdown.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CollectionDropDown.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomAppBar.dart';
import 'package:ownerchip_whitelabel/widgets/ui/returnSnackBarWidget.dart';

//import services
import 'package:ownerchip_whitelabel/services/providers.service.dart';
import 'package:ownerchip_whitelabel/services/walletconnect.services.dart';

//import screens
import 'package:ownerchip_whitelabel/screens/MetadataInputScreen.dart';

//import misc
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';

class ChainSelectorScreen extends ConsumerStatefulWidget {
  const ChainSelectorScreen({Key? key}) : super(key: key);

  static const routeName = '/chainSelector';

  @override
  _ChainSelectorScreen createState() => _ChainSelectorScreen();
}

class _ChainSelectorScreen extends ConsumerState<ChainSelectorScreen> {
  void onInitializeButtonPress(
      BuildContext context, WalletConnect wc, mounted) async {
    final wc = ref.watch(walletConnectProvider);
    try {
      if (!wc.connected) {
        await startWalletConnection(context, wc);
      }

      if (mounted) {
        Navigator.pushNamed(context, MetadataScreen.routeName);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        returnSnackBarWidget(context.loc.errorHeadingSnackBar,
            context.loc.errorConnectingWallet, 'error'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final wc = ref.watch(walletConnectProvider);

    return Scaffold(
      appBar: const CustomAppBar(
        text: 'Select chain',
        showBackButton: true,
      ),
      body: ScreenBodyLayout(
        withScrollView: false,
        children: [
          const SizedBox(height: 20),
          Text(
            textAlign: TextAlign.center,
            context.loc.chooseChain,
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: 20),
          Text(
            context.loc.selectBlockchain,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 5),
          const ChainDropdown(),
          const SizedBox(height: 20),
          Text(
            context.loc.selectCollection,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 5),
          const CollectionDropdown(),
          const SizedBox(height: 20),
          CustomRoundedButton(
            text: 'Next',
            onPressed: () {
              onInitializeButtonPress(context, wc, mounted);
            },
          ),
        ],
      ),
    );
  }
}
