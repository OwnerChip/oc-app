import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:flutter/gestures.dart';
import 'package:ownerchip_whitelabel/widgets/ui/AuthPopup.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:web3dart/credentials.dart';
import '../../utils/utils.dart';
import 'returnSnackBarWidget.dart';
import '../../utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/services/walletconnect.services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/services/providers.services.dart';
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
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                // trust wallet
                GestureDetector(
                    onTap: () {
                      onWalletPress(context, ref, wc,
                          walletConfig['https://trustwallet.com']!);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                            decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 243, 243, 243),
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(13)),
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
                                  walletConfig['https://trustwallet.com']!
                                      .iconUri,
                                  fit: BoxFit.contain),
                            )),
                        Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              walletConfig['https://trustwallet.com']!.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .displaySmall!
                                  .copyWith(fontSize: 14),
                            ))
                      ],
                    )),
                // metamask wallet
                GestureDetector(
                    onTap: () {
                      onWalletPress(context, ref, wc,
                          walletConfig['https://metamask.io/']!);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 243, 243, 243),
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(13)),
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
                                    walletConfig['https://metamask.io/']!
                                        .iconUri,
                                    fit: BoxFit.contain))),
                        Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              walletConfig['https://metamask.io/']!.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .displaySmall!
                                  .copyWith(
                                    fontSize: 14,
                                  ),
                            ))
                      ],
                    )),
              ]),
              const SizedBox(height: 30),
              Text(
                'When signing in via Metamask make sure to connect with Ethereum Mainnet.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
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
    authPopupBuilder(context, ref, wc);
    Navigator.pop(context);
  } catch (e) {
    //show error snackbar
    ScaffoldMessenger.of(context).showSnackBar(returnSnackBarWidget(
        context.loc.errorHeadingSnackBar,
        'User denied connection request.',
        'error'));
  }
}
