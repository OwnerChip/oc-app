import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomAppBar.dart';
import 'package:ownerchip_whitelabel/services/providers.service.dart';
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';
import 'package:ownerchip_whitelabel/widgets/ui/ChainDropdown.dart';

class ChainSelectorScreen extends ConsumerStatefulWidget {
  const ChainSelectorScreen({super.key});

  static const routeName = '/chainSelector';

  @override
  _ChainSelectorScreen createState() => _ChainSelectorScreen();
}

class _ChainSelectorScreen extends ConsumerState<ChainSelectorScreen> {
  @override
  Widget build(BuildContext context) {
    final wc = ref.watch(walletConnectProvider);
    final chainId = ref.watch(chainIdProvider);

    return Scaffold(
      appBar: CustomAppBar(
        text: 'Select a blockchain',
        showBackButton: true,
        connectedWalletAddress: wc.session.accounts[0],
      ),
      body: ScreenBodyLayout(
        children: [
          const SizedBox(height: 20),
          Text(
            'Select a blockchain',
            style: Theme.of(context).textTheme.headline1,
          ),
          const SizedBox(height: 20),
          Text(
            'Select a blockchain to connect to',
            style: Theme.of(context).textTheme.bodyText1,
          ),
          const SizedBox(height: 20),
          const ChainDropdown()
        ],
      ),
    );
  }
}
