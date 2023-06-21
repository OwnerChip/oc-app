import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import '../../utils/utils.dart';
import 'returnSnackBarWidget.dart';
import '../../utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/services/walletconnect.services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/services/providers.service.dart';
import 'package:ownerchip_whitelabel/config/wallets.dart';

Future<void> walletPopupBuilder(
    BuildContext context, WidgetRef ref, Web3App wc) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
          //border radius
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20.0))),
          title: const Padding(
            padding: EdgeInsets.only(top: 20, bottom: 10),
            child: Text(
              'Choose wallet to connect',
              textAlign: TextAlign.center,
            ),
          ),
          titleTextStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 112, 112, 112)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                      onTap: () {
                        onWalletPress(context, ref, wc,
                            walletConfig['Trust Wallet']!.deeplinkUri);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                              decoration: BoxDecoration(
                                  color:
                                      const Color.fromARGB(255, 243, 243, 243),
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(13)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: CustomColors(dotenv.get('APP_ID'))
                                          .secondaryShadowColor,
                                      offset: const Offset(1, 3),
                                      blurRadius: 5,
                                    )
                                  ]),
                              width: 60,
                              height: 60,
                              child: Padding(
                                padding: const EdgeInsets.all(7),
                                child: Image.asset(
                                    walletConfig['Trust Wallet']!.iconUri,
                                    fit: BoxFit.contain),
                              )),
                          Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(
                                walletConfig['Trust Wallet']!.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .displaySmall!
                                    .copyWith(fontSize: 14),
                              ))
                        ],
                      )),
                  GestureDetector(
                      onTap: () {
                        onWalletPress(context, ref, wc,
                            walletConfig['Metamask']!.deeplinkUri);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                  color:
                                      const Color.fromARGB(255, 243, 243, 243),
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(13)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: CustomColors(dotenv.get('APP_ID'))
                                          .secondaryShadowColor,
                                      offset: const Offset(1, 3),
                                      blurRadius: 5,
                                    )
                                  ]),
                              child: Padding(
                                  padding: const EdgeInsets.all(7),
                                  child: Image.asset(
                                      walletConfig['Metamask']!.iconUri,
                                      fit: BoxFit.contain))),
                          Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(
                                walletConfig['Metamask']!.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .displaySmall!
                                    .copyWith(
                                      fontSize: 14,
                                    ),
                              ))
                        ],
                      ))
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 50),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.grey),
                    children: [
                      const TextSpan(
                          text: 'By connecting your wallet you agree to our '),
                      TextSpan(
                        text: 'terms of service',
                        style: const TextStyle(color: Colors.blue),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            await launchUrl(Uri.parse('https://flutter.dev'));
                          },
                      ),
                      const TextSpan(
                        text: ' and ',
                      ),
                      TextSpan(
                        text: 'privacy policy',
                        style: const TextStyle(color: Colors.blue),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            await launchUrl(Uri.parse('https://flutter.dev'));
                          },
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

//TODO: Move this to PopUp.dart
Future<void> onWalletPress(
    BuildContext context, WidgetRef ref, Web3App wc, String walletLink) async {
  final wcSession = ref.watch(wcSessionProvider);
  try {
    //check if there is internet connections
    if (!await checkInternetConnection()) {
      throw Exception("No internet connection");
    }
    //if wallet is connected then kill session, else connect wallet

    await startWalletConnection(context, ref, wc, walletLink);
    Navigator.pop(context);
  } catch (e) {
    //show error snackbar
    ScaffoldMessenger.of(context).showSnackBar(returnSnackBarWidget(
        context.loc.errorHeadingSnackBar,
        context.loc.errorNoInternetConnection,
        'error'));
  }
}
