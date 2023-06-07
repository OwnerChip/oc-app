// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import '../../utils/utils.dart';
import 'returnSnackBarWidget.dart';
import '../../utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/services/walletconnect.services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/services/providers.service.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:walletconnect_qrcode_modal_dart/walletconnect_qrcode_modal_dart.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const CustomAppBar({Key? key, this.text, this.showBackButton = true})
      : super(key: key);
  final String? text;
  final bool showBackButton; //valid values: 'back', 'logo'

  void onButtonPress(BuildContext context, WalletConnect wc) async {
    try {
      //check if there is internet connections
      if (!await checkInternetConnection()) {
        throw Exception("No internet connection");
      }
      //if wc bridge is not connected, then reconnect
      if (!wc.bridgeConnected) {
        wc.reconnect();
      }
      //if wallet is connected then kill session, else connect wallet
      if (wc.connected) {
        wc.killSession();
      } else {
        startWalletConnection(context, wc);
      }
    } catch (e) {
      //show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(returnSnackBarWidget(
          context.loc.errorHeadingSnackBar,
          context.loc.errorNoInternetConnection,
          'error'));
    }
  }

  void onButtonPress2(
      BuildContext context, WidgetRef ref, Web3App wcClient) async {
    ConnectResponse resp = await wcClient.connect(requiredNamespaces: {
      'eip155': const RequiredNamespace(
        chains: ['eip155:1'], // Ethereum chain
        methods: [
          'eth_sendTransaction',
          'eth_signTypedData',
          'personal_sign'
        ], // Requestable Methods
        events: ['accountsChanged'], // Requestable Methods
      ),
    });
    String? uri = resp.uri.toString();
    String walletLink = 'https://link.trustwallet.com';
    Uri walletDeepLink = convertToWcLink(appLink: walletLink, wcUri: uri);

    print(walletDeepLink);

    await launchUrlString(walletDeepLink.toString(),
        mode: LaunchMode.externalApplication);

    final SessionData session = await resp.session.future;
    print(session);

    ref.read(sessionProvider2.notifier).state = session;
  }

  //necessary to use because flutter?!
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WalletConnect wc = ref.watch(walletConnectProvider);
    Web3App? wcClient = ref.watch(walletConnectProvider2);
    SessionData? session = ref.watch(sessionProvider2);
    return AppBar(
      automaticallyImplyLeading: false,
      leadingWidth: !showBackButton
          ? 120
          : null, //only change leading width if logo is shown
      leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: showBackButton
              ? Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    IconButton(
                      padding: const EdgeInsets.all(0.0),
                      icon: SvgPicture.asset(
                          "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/back.svg"),
                      color: CustomColors(dotenv.get('APP_ID')).black,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                )
              : Image.asset(
                  '${dotenv.get('IMAGE_ASSETS_BASE_URL')}/app_logo.png',
                  fit: BoxFit.contain)),
      title: Text(text ?? '', style: Theme.of(context).textTheme.displaySmall),
      centerTitle: true,
      actions: [
        Padding(
            padding: const EdgeInsets.only(right: 5),
            child: session != null
                ? Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      IconButton(
                        padding: const EdgeInsets.all(0.0),
                        icon: Icon(Icons.logout,
                            color:
                                CustomColors(dotenv.get('APP_ID')).primaryColor,
                            size: 35),
                        color: CustomColors(dotenv.get('APP_ID')).black,
                        // onPressed: () => onButtonPress(context, wc),
                        onPressed: () =>
                            onButtonPress2(context, ref, wcClient!),
                      ),
                      Align(
                        alignment: const Alignment(0.0, 0.95),
                        child: Text(
                          context.loc.disconnect,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(fontSize: 12),
                        ),
                      ),
                    ],
                  )
                : Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      IconButton(
                        padding: const EdgeInsets.all(0.0),
                        icon: Icon(Icons.wallet,
                            color:
                                CustomColors(dotenv.get('APP_ID')).primaryColor,
                            size: 35),
                        color: CustomColors(dotenv.get('APP_ID')).black,
                        // onPressed: () => onButtonPress(context, wc),
                        onPressed: () =>
                            onButtonPress2(context, ref, wcClient!),
                      ),
                      Align(
                        alignment: const Alignment(0.0, 0.95),
                        child: Text(
                          context.loc.connect,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(fontSize: 10),
                        ),
                      ),
                    ],
                  ))
      ],
      titleTextStyle: Theme.of(context).textTheme.displaySmall,
      backgroundColor: Colors.transparent,
      elevation: 0,
    );
  }
}
