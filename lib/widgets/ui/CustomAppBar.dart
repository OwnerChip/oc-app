// ignore_for_file: use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  final bool showBackButton;

  Future<void> onButtonPress(
      BuildContext context, WidgetRef ref, Web3App wc) async {
    final wcSession = ref.watch(wcSessionProvider);
    try {
      //check if there is internet connections
      if (!await checkInternetConnection()) {
        throw Exception("No internet connection");
      }
      //if wallet is connected then kill session, else connect wallet
      if (wcSession != null) {
        //TODO: find CORRECT SESSION & add proper message
        wc.disconnectSession(
            topic: wcSession.topic,
            reason:
                WalletConnectError(code: 6000, message: 'MANUAL DISCONNECT'));
        ref.read(wcSessionProvider.notifier).state = null;
      } else {
        final wcResp = await startWalletConnection(context, ref, wc);
        final session = await wcResp.session.future;
        ref.read(wcSessionProvider.notifier).state = session;
      }
    } catch (e) {
      //show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(returnSnackBarWidget(
          context.loc.errorHeadingSnackBar,
          context.loc.errorNoInternetConnection,
          'error'));
    }
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
                // DISCONNECT
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
                        onPressed: () => onButtonPress(context, ref, wcClient!),
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
                // CONNECT
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
                        onPressed: () => onButtonPress(context, ref, wcClient!),
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
