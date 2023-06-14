// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ownerchip_whitelabel/domain/eip155.dart';
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

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const CustomAppBar({Key? key, this.text, this.showBackButton = true})
      : super(key: key);
  final String? text;
  final bool showBackButton; //valid values: 'back', 'logo'

  void onButtonPress(BuildContext context, WidgetRef ref, Web3App wc) async {
    final wcSession = ref.watch(wcSessionProvider);
    try {
      //check if there is internet connections
      if (!await checkInternetConnection()) {
        throw Exception("No internet connection");
      }
      //if wc bridge is not connected, then reconnect
      if (wcSession == null) {
        startWalletConnection(context, ref, wc);
      }
      //if wallet is connected then kill session, else connect wallet
      if (wcSession != null) {
        //TODO: add proper values
        wc.disconnectSession(
            topic: 'topic',
            reason: WalletConnectError(code: 1, message: 'MANUAL DISCONNECT'));
      } else {
        startWalletConnection(context, ref, wc);
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
    ConnectResponse? resp = await startWalletConnection(context, ref, wcClient);
    String? uri = resp?.uri.toString() ?? '';

    //TODO: DO USE A DEDICATED FUNCTION INSTEAD!
    String walletLink = 'https://link.trustwallet.com';
    Uri walletDeepLink = convertToWcLink(appLink: walletLink, wcUri: uri);

    await launchUrlString(walletDeepLink.toString(),
        mode: LaunchMode.externalApplication);
  }

  //necessary to use because flutter?!
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Web3App? wcClient = ref.watch(wcProvider);
    SessionData? wcSession = ref.watch(wcSessionProvider);
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
            child: wcSession != null
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
