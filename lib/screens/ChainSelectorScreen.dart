//import packages

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/domain/blockchainCollectionList/blockchainCollectionList.dart';
import 'package:ownerchip_whitelabel/domain/collection/collection.dart';
//import screens
import 'package:ownerchip_whitelabel/screens/MetadataInputScreen.dart';
import 'package:ownerchip_whitelabel/services/providers/collectionsData.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
//import misc
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/utils/navigationArguments.dart';
//import widgets
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';
import 'package:ownerchip_whitelabel/widgets/popups/WalletPopUp.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:ownerchip_whitelabel/widgets/ui/ChainDropdown.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CollectionDropDown.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/appBar/CustomAppBar.dart';
import 'package:sentry/sentry.dart';
import 'package:web3dart/web3dart.dart';

class ChainSelectorScreen extends ConsumerStatefulWidget {
  const ChainSelectorScreen({Key? key}) : super(key: key);

  static const routeName = '/chainSelector';

  @override
  _ChainSelectorScreen createState() => _ChainSelectorScreen();
}

class _ChainSelectorScreen extends ConsumerState<ChainSelectorScreen> {
  void onInitializeButtonPress(
      BuildContext context, mounted, String sessionId) async {
    final wcSession = ref.read(wcSessionProvider);
    BlockchainCollectionList relevantCollections =
        await ref.read(findAllMinterRolesProvider.future);
    final int? chainId = ref.read(selectedChainIdProvider);
    final Collection? collection = ref.read(selectedCollectionIdProvider);
    try {
      if (wcSession == null) {
        walletPopupBuilder(context, ref);
      }

      if (mounted) {
        EthereumAddress userAddr = ref.watch(userAddressProvider);
        Sentry.configureScope(
          (scope) => scope.setUser(SentryUser(id: userAddr.toString())),
        );
        if (chainId != null && collection != null) {
          Navigator.pushNamed(context, MetadataScreen.routeName,
              arguments: MetadataInputScreenArguments(
                  sessionId, chainId, collection.id,
                  voucherAddress: collection.voucherAddress));
        }
      }
    } catch (e, s) {
      await Sentry.captureException(
        e,
        stackTrace: s,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        returnSnackBarWidget(context.loc.errorHeadingSnackBar,
            context.loc.errorConnectingWallet, 'error'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final int? chainId = ref.watch(selectedChainIdProvider);
    final Collection? collection = ref.watch(selectedCollectionIdProvider);
    final navArgs = ModalRoute.of(context)!.settings.arguments
        as MetadataInputScreenArguments;
    return Scaffold(
      appBar: CustomAppBar(
        text: context.loc.selectChain,
        showBackButton: true,
      ),
      body: ScreenBodyLayout(
        withScrollView: false,
        children: [
          Row(
            children: [
              const SizedBox(width: 22),
              RichText(
                text: TextSpan(
                    text: '${context.loc.step} 1/',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge!
                        .copyWith(fontSize: 18),
                    children: [
                      TextSpan(
                          text: '2',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall!
                              .copyWith(fontSize: 18))
                    ]),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Text(
            context.loc.creationOfTwin,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                  fontSize: 24,
                ),
          ),
          const SizedBox(height: 30),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                context.loc.selectBlockchain,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 5),
              const ChainDropdown(),
              const SizedBox(height: 20),
              Text(
                context.loc.selectCollection,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 5),
              const CollectionDropdown(),
              const SizedBox(height: 20),
            ],
          ),
          CustomRoundedButton(
            text: context.loc.next,
            onPressed: chainId == null || collection == null
                ? null
                : () {
                    onInitializeButtonPress(
                        context, mounted, navArgs.sessionId);
                  },
          ),
        ],
      ),
    );
  }
}
