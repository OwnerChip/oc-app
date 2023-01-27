import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:walletconnect_secure_storage/walletconnect_secure_storage.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flutter/material.dart';
import 'package:ownerchip_whitelabel/widgets/ui/returnSnackBarWidget.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

//create wallet connector function
Future<WalletConnect> createWalletConnector() async {
  WalletConnectSecureStorage sessionStorage = WalletConnectSecureStorage();
  WalletConnectSession? session = await sessionStorage.getSession();

  return WalletConnect(
      bridge: 'https://bridge.walletconnect.org',
      session: session == null || !session.connected ? null : session,
      sessionStorage: sessionStorage,
      clientMeta: const PeerMeta(
        name: 'OwnerChip Demo',
        description: 'Connecting physical objects to the blockchain.',
        url: 'https://walletconnect.org',
        // icons: ["${dotenv.get('IMAGE_ASSETS_BASE_URL')}/app_logo.png"]
      ));
}

Future<void> startWalletConnection(
    BuildContext context, WalletConnect connector) async {
  await dotenv.load(fileName: ".env");
  int chainId = int.parse(dotenv.get('CHAIN_ID'));
  // if (!connector.connected) {
  try {
    // var chainId = int.parse(dotenv.get('CHAIN_ID', fallback: 1));
    var sessionStatus = await connector.connect(
        chainId: chainId,
        onDisplayUri: (uri) async {
          await launchUrlString(uri, mode: LaunchMode.externalApplication);
        });

    //save session
    connector.sessionStorage?.store(connector.session);

    // if (!mounted) {
    //   return;
    // }
  } catch (e) {
    //returnSnackBar
    ScaffoldMessenger.of(context).showSnackBar(returnSnackBarWidget(
        context.loc.errorHeadingSnackBar,
        context.loc.errorConnectingWallet,
        'success'));
    print(e);
  }
  // }
}
