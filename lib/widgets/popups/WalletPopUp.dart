import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/screens/PinScreen.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/services/scan.services.dart';
import 'package:flutter/gestures.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/navigationArguments.dart';
import 'package:ownerchip_whitelabel/widgets/popups/AuthPopup.dart';
import 'package:ownerchip_whitelabel/widgets/popups/CustomPopup.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:ownerchip_whitelabel/widgets/ui/PukDisplay.dart';
import 'package:ownerchip_whitelabel/widgets/ui/WalletIcon.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import '../../utils/utils.dart';
import '../../utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/services/wallet.services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/config/wallets.dart';
import 'package:ownerchip_whitelabel/themes/fontSpecs.dart';

Future<void> walletPopupBuilder(BuildContext context, WidgetRef ref) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20.0))),
          title: Padding(
            padding: EdgeInsets.only(top: 20, bottom: 10),
            child: Text(
              context.loc.chooseWallet,
              textAlign: TextAlign.center,
            ),
          ),
          titleTextStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(
              fontSize: CustomFonts(dotenv.get('APP_ID')).metadataNameFontSize,
              fontWeight:
                  CustomFonts(dotenv.get('APP_ID')).metadataNameFontWeight),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                // OwnerCard wallet
                WalletIcon(
                  iconPath:
                      "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/ownercard_logo.png",
                  walletName: context.loc.ownercard,
                  onTap: () async {
                    await Navigator.pushNamed(context, PinScreen.routeName,
                        arguments: PinScreenArguments(
                            activeFeature: PinScreenActiveFeature.verifyPinAuth,
                            callback: (String pin) async {
                              onCardPress(ref, context, pin);
                            }));
                  },
                  backgroundColor: CustomColors(dotenv.get('APP_ID'))
                      .ownerCardWalletIconBackgroundColor,
                ),
                // trust wallet
                WalletIcon(
                    iconPath: walletConfig['https://trustwallet.com']!.iconUri,
                    walletName: walletConfig['https://trustwallet.com']!.name,
                    onTap: () => onWalletPress(context, ref,
                        walletConfig['https://trustwallet.com']!)),
              ]),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                // metamask
                WalletIcon(
                  iconPath: walletConfig['https://metamask.io/']!.iconUri,
                  walletName: walletConfig['https://metamask.io/']!.name,
                  onTap: () => onWalletPress(
                      context, ref, walletConfig['https://metamask.io/']!),
                ),

                //1inch
                WalletIcon(
                    iconPath: walletConfig['https://1inch.io/wallet/']!.iconUri,
                    walletName: walletConfig['https://1inch.io/wallet/']!.name,
                    onTap: () => onWalletPress(context, ref,
                        walletConfig['https://1inch.io/wallet/']!)),
              ]),
              Padding(
                padding: const EdgeInsets.only(top: 30),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.grey),
                    children: [
                      TextSpan(text: context.loc.agreeToWhenConnecting),
                      TextSpan(
                        text: context.loc.generalTerms,
                        style: const TextStyle(color: Colors.blue),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            await launchUrl(
                                Uri.parse(context.loc.termsAndConditionsUrl));
                          },
                      ),
                      TextSpan(
                        text: " ${context.loc.and} ",
                      ),
                      TextSpan(
                        text: context.loc.privacyPolicy,
                        style: const TextStyle(color: Colors.blue),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            await launchUrl(Uri.parse(context.loc.privacyUrl));
                          },
                      ),
                      TextSpan(
                        text: "${context.loc.zu}.",
                      ),
                    ],
                  ),
                ),
              )
            ],
          ));
    },
  );
}

Future<void> onWalletPress(
    BuildContext context, WidgetRef ref, WalletType wallet) async {
  try {
    if (!await checkInternetConnection()) {
      throw "No internet connection";
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(returnSnackBarWidget(
        context.loc.errorHeadingSnackBar,
        context.loc.errorNoInternetConnection,
        'error'));
    return;
  }

  try {
    Web3App? wc = ref.read(wcProvider);
    if (wc == null) {
      wc = await initWcClient(ref);
    }
    ConnectResponse response =
        await startWalletConnection(context, ref, wc, wallet);
    var futureRes = await response.session.future;
    authPopupBuilder(context, ref, wc, wallet.name);

    Navigator.pop(context);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(returnSnackBarWidget(
        context.loc.errorHeadingSnackBar, 'Error connecting wallet.', 'error'));
  }
}

Future<void> onCardPress(
    WidgetRef ref, BuildContext context, String pin) async {
  try {
    if (!await checkInternetConnection()) {
      throw "No internet connection";
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(returnSnackBarWidget(
        context.loc.errorHeadingSnackBar,
        context.loc.errorNoInternetConnection,
        'error'));
    return;
  }
  await authenticateCard(ref, context, pin);
  ScaffoldMessenger.of(context).showSnackBar(returnSnackBarWidget(
      context.loc.successHeadingSnackbar,
      context.loc.successCardLogin,
      'success'));
  //navigate to previous screen
  Navigator.pop(context);
  //remove wallet popup
  Navigator.pop(context);
}

Future<void> onAddCardPress(
    WidgetRef ref, BuildContext context, String pin) async {
  String? puk = await setPinOnCard(context, ref, pin);
  if (puk == null) {
    throw Exception("Error setting pin");
  }
  showCustomPopup(context, context.loc.successfullySetUpPin,
      PukDisplay(pin: pin, puk: puk));
}
