// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import '../../utils/utils.dart';
import 'returnSnackBarWidget.dart';
import '../../utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/services/walletconnect.services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/services/providers.service.dart';

class CustomAppBar extends ConsumerWidget with PreferredSizeWidget {
  const CustomAppBar(
      {Key? key,
      this.text,
      this.connectedWalletAddress,
      this.showBackButton = true})
      : super(key: key);
  final String? text;
  final String? connectedWalletAddress;
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

  //necessary to use because flutter?!
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WalletConnect wc = ref.watch(walletConnectProvider);
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
                      color: CustomColors(dotenv.get('STYLE_ID')).black,
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
            child: wc.connected
                ? Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      IconButton(
                        padding: const EdgeInsets.all(0.0),
                        icon: SvgPicture.asset(
                            "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/disconnect.svg"),
                        color: CustomColors(dotenv.get('STYLE_ID')).black,
                        onPressed: () => onButtonPress(context, wc),
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
                        icon: SvgPicture.asset(
                            "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/connect.svg"),
                        color: CustomColors(dotenv.get('STYLE_ID')).black,
                        onPressed: () => onButtonPress(context, wc),
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
