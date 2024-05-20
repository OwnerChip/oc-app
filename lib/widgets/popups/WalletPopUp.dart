import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/config/wallets.dart';
import 'package:ownerchip_whitelabel/screens/PinScreen.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/services/nfc.services.dart';
import 'package:flutter/gestures.dart';
import 'package:ownerchip_whitelabel/services/providers/web3auth/web3authNotifier.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/globals.dart';
import 'package:ownerchip_whitelabel/utils/navigationArguments.dart';
import 'package:ownerchip_whitelabel/widgets/popups/AuthPopup.dart';
import 'package:ownerchip_whitelabel/widgets/popups/CustomPopup.dart';
import 'package:ownerchip_whitelabel/widgets/ui/PukDisplay.dart';
import 'package:ownerchip_whitelabel/widgets/ui/WalletIcon.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web3auth_flutter/input.dart';
import 'package:web3auth_flutter/web3auth_flutter.dart';
import 'package:web3auth_flutter/enums.dart' as web3auth;
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
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                runAlignment: WrapAlignment.center,
                runSpacing: 24,
                alignment: WrapAlignment.center,
                children: [
                  // OwnerCard wallet
                  WalletIcon(
                    iconPath:
                        "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/ownercard_logo.png",
                    walletName: context.loc.ownercard,
                    onTap: () async {
                      await Navigator.pushNamed(context, PinScreen.routeName,
                          arguments: PinScreenArguments(
                              activeFeature:
                                  PinScreenActiveFeature.verifyPinAuth,
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
                        );
                      }
                    },
                    backgroundColor: CustomColors(dotenv.get('APP_ID'))
                        .ownerCardWalletIconBackgroundColor,
                  ),
                  WalletIcon(
                    iconPath: "assets/images/common/google.svg",
                    walletName: 'Google',
                    onTap: () async {
                      Navigator.pop(context);
                      await Web3AuthFlutter.login(
                        LoginParams(loginProvider: web3auth.Provider.google),
                      ).then((e) {
                        final Web3AuthNotifier web3AuthNotifier =
                            ref.read(web3AuthNotifierProvider.notifier);

                        //set session and wallet type provider
                        web3AuthNotifier.setWeb3AuthResponse(e);
                        ref.read(walletTypeProvider.notifier).state =
                            walletConfig[EWalletType.web3auth];

                        //store session and wallet type
                        final storage = SharedPreferences.getInstance();
                        if (e.sessionId != null) {
                          storage.then((value) =>
                              value.setString('session', e.sessionId!));
                        }
                        storage.then((value) => value.setString(
                            'walletType',
                            jsonEncode(
                                walletConfig[EWalletType.web3auth]!.toJson())));

                        ref.read(userAddressProvider.notifier).state =
                            EthPrivateKey.fromHex(e.privKey!).address;

                        authPopupBuilder(
                          navigatorKey.currentContext!,
                          ref,
                        );
                      });
                    },
                    backgroundColor: CustomColors(dotenv.get('APP_ID'))
                        .ownerCardWalletIconBackgroundColor,
                  ),
                ],
              ),
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
              ),
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
