import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/screens/HomeScreen.dart';
import 'package:ownerchip_whitelabel/screens/PinScreen.dart';
import 'package:ownerchip_whitelabel/services/scan.services.dart';
import 'package:flutter/gestures.dart';
import 'package:ownerchip_whitelabel/utils/navigationArguments.dart';
import 'package:ownerchip_whitelabel/widgets/popups/AuthPopup.dart';
import 'package:ownerchip_whitelabel/widgets/popups/CustomPopup.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:ownerchip_whitelabel/widgets/ui/PukDisplay.dart';
import 'package:ownerchip_whitelabel/widgets/ui/SuccessPinSetup.dart';
import 'package:ownerchip_whitelabel/widgets/ui/WalletIcon.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import '../../utils/utils.dart';
import '../../utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/services/wallet.services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/config/wallets.dart';
import 'package:ownerchip_whitelabel/themes/fontSpecs.dart';

//import customfont

Future<void> walletPopupBuilder(
    BuildContext context, WidgetRef ref, Web3App wc) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          //border radius
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
                    "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/ownercard_logo.png",
                    context.loc.ownercard, () async {
                  // Navigator.pop(context); //remove wallet popup

                  await Navigator.pushNamed(context, PinScreen.routeName,
                      arguments: PinScreenArguments(
                          activeFeature: PinScreenActiveFeature.verifyPinAuth,
                          callback: (String pin) async {
                            onCardPress(ref, context, pin);
                          }));
                }),
                // trust wallet
                WalletIcon(
                    walletConfig['https://trustwallet.com']!.iconUri,
                    walletConfig['https://trustwallet.com']!.name,
                    () => onWalletPress(context, ref, wc,
                        walletConfig['https://trustwallet.com']!)),
              ]),
              const SizedBox(height: 20),

              Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                // metamask
                WalletIcon(
                    walletConfig['https://metamask.io/']!.iconUri,
                    walletConfig['https://metamask.io/']!.name,
                    () => onWalletPress(context, ref, wc,
                        walletConfig['https://metamask.io/']!)),

                //1inch
                WalletIcon(
                    walletConfig['https://1inch.io/wallet/']!.iconUri,
                    walletConfig['https://1inch.io/wallet/']!.name,
                    () => onWalletPress(context, ref, wc,
                        walletConfig['https://1inch.io/wallet/']!)),
              ]),
              // const SizedBox(height: 20),
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.start,
              //   children: [
              //     // 1inch
              //     WalletIcon(
              //         walletConfig['https://1inch.io/wallet/']!.iconUri,
              //         walletConfig['https://1inch.io/wallet/']!.name,
              //         () => onWalletPress(context, ref, wc,
              //             walletConfig['https://1inch.io/wallet/']!)),
              //   ],
              // ),
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
                                Uri.parse(dotenv.get('TERMS_PAGE_URL')));
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
                            await launchUrl(
                                Uri.parse(dotenv.get('LEGAL_PAGE_URL')));
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
    BuildContext context, WidgetRef ref, Web3App wc, WalletType wallet) async {
  try {
    //check if there is internet connections
    if (!await checkInternetConnection()) {
      throw Exception("No internet connection");
    }
    ConnectResponse response =
        await startWalletConnection(context, ref, wc, wallet);
    var futureRes = await response.session.future;
    authPopupBuilder(context, ref, wc, wallet.name);
    Navigator.pop(context);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(returnSnackBarWidget(
        context.loc.errorHeadingSnackBar,
        'User denied connection request.',
        'error'));
  }
}

Future<void> onCardPress(
    WidgetRef ref, BuildContext context, String pin) async {
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
