// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import '../../utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/widgets/popups/WalletPopUp.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:web3modal_flutter/web3modal_flutter.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.text,
    this.showBackButton = true,
    this.showWalletButton = true,
  });

  final String? text;
  final bool showBackButton;
  final bool showWalletButton;

  //necessary to use because flutter?!
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Web3App? wc = ref.watch(wcProvider);
    SessionData? wcSession = ref.watch(wcSessionProvider);
    UserSession? userSession = ref.watch(userSessionProvider);
    return AppBar(
      automaticallyImplyLeading: false,
      leadingWidth: !showBackButton ? 120 : null,
      //only change leading width if logo is shown
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
                  '${dotenv.get('IMAGE_ASSETS_BASE_URL')}/app_logo_appbar.png',
                  fit: BoxFit.contain)),
      title: Text(text ?? '', style: Theme.of(context).textTheme.displaySmall),
      centerTitle: true,
      actions: [
        if (showWalletButton)
          Padding(
              padding: const EdgeInsets.only(right: 5),
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  userSession != null
                      ? IconButton(
                          padding: const EdgeInsets.all(0.0),
                          icon: Icon(Icons.logout,
                              color: CustomColors(dotenv.get('APP_ID'))
                                  .primaryColor,
                              size: 35),
                          color: CustomColors(dotenv.get('APP_ID')).black,
                          onPressed: () async {
                            //navigate back until homescreen
                            Navigator.of(context)
                                .popUntil((route) => route.isFirst);
                            //reset providers
                            ref.read(userAddressProvider.notifier).state =
                                zeroAddress;
                            ref.read(walletTypeProvider.notifier).state = null;
                            ref.read(userSessionProvider.notifier).state = null;

                            final storage =
                                await SharedPreferences.getInstance();

                            //remove session and wallet type from storage
                            storage.remove('session');
                            storage.remove('walletType');
                            storage.remove('userSession');

                            if (wc != null && wcSession != null) {
                              wc.disconnectSession(
                                  topic: wcSession.topic,
                                  reason: const WalletConnectError(
                                      code: 6000,
                                      message:
                                          'MANUAL DISCONNECT')); //WC disconnect event is triggered and riverpod state is deleted in listener
                            }
                          },
                        )
                      : IconButton(
                          padding: const EdgeInsets.all(0.0),
                          icon: Icon(Icons.wallet,
                              color: CustomColors(dotenv.get('APP_ID'))
                                  .primaryColor,
                              size: 35),
                          color: CustomColors(dotenv.get('APP_ID')).black,
                          onPressed: () async {
                            walletPopupBuilder(context, ref);
                          },
                        ),
                  Align(
                    alignment: const Alignment(0.0, 0.95),
                    child: Text(
                      userSession != null
                          ? context.loc.disconnect
                          : context.loc.connect,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(fontSize: 12),
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
