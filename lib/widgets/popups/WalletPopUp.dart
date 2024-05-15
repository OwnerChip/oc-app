import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/screens/PinScreen.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/services/nfc.services.dart';
import 'package:flutter/gestures.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/globals.dart';
import 'package:ownerchip_whitelabel/utils/navigationArguments.dart';
import 'package:ownerchip_whitelabel/widgets/popups/AuthPopup.dart';
import 'package:ownerchip_whitelabel/widgets/popups/CustomPopup.dart';
import 'package:ownerchip_whitelabel/widgets/ui/PukDisplay.dart';
import 'package:ownerchip_whitelabel/widgets/ui/WalletIcon.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/services/wallet.services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/themes/fontSpecs.dart';
import 'package:web3modal_flutter/web3modal_flutter.dart';

Future<void> walletPopupBuilder(BuildContext context, WidgetRef ref) async {
  final W3MService? w3mService = ref.read(w3mServiceProvider);
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
                              onCardPress(ref, context, pin, true);
                            }));
                  },
                  backgroundColor: CustomColors(dotenv.get('APP_ID'))
                      .ownerCardWalletIconBackgroundColor,
                ),
                WalletIcon(
                  iconPath:
                      "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/walletconnect.png",
                  walletName: 'WalletConnect',
                  onTap: () async {
                    Navigator.pop(context);
                    await w3mService!.disconnect();
                    await w3mService.openModal(navigatorKey.currentContext!);
                    if (ref.read(wcSessionProvider) != null) {
                      authPopupBuilder(
                        navigatorKey.currentContext!,
                        ref,
                        w3mService.web3App! as Web3App,
                        "WalletConnect",
                      );
                    }
                  },
                  backgroundColor: CustomColors(dotenv.get('APP_ID'))
                      .ownerCardWalletIconBackgroundColor,
                ),
              ]),
              const SizedBox(height: 20),
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

Future<void> onAddCardPress(
    WidgetRef ref, BuildContext context, String pin) async {
  String? puk = await setPinOnCard(context, ref, pin);
  if (puk == null) {
    throw Exception("Error setting pin");
  }
  showCustomPopup(context, context.loc.successfullySetUpPin,
      PukDisplay(pin: pin, puk: puk));
}
