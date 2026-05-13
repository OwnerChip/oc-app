import 'dart:convert';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/config/wallets.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/domain/jwt/jwt_token.dart';
import 'package:ownerchip_whitelabel/screens/PinScreen.dart';
import 'package:ownerchip_whitelabel/services/backend/app/backendApp.dart';
import 'package:ownerchip_whitelabel/services/backend/auth/backendAuth.dart';
import 'package:ownerchip_whitelabel/services/backend/backend.services.dart';
import 'package:ownerchip_whitelabel/services/backend/creator/backendCreator.dart';
import 'package:ownerchip_whitelabel/services/backend/creator/payloads/updateWeb3AuthDataPayload.dart';
import 'package:ownerchip_whitelabel/services/backend/fcm/backendFcm.dart';
import 'package:ownerchip_whitelabel/services/nfc.services.dart';
import 'package:ownerchip_whitelabel/services/providers/accountDeletionRequest/accountDeletionRequestNotifier.dart';
import 'package:ownerchip_whitelabel/services/providers/collectionsData.dart';
import 'package:ownerchip_whitelabel/services/providers/creations/creationsNotifier.dart';
import 'package:ownerchip_whitelabel/services/providers/myBalance/myBalanceNotifier.dart';
import 'package:ownerchip_whitelabel/services/providers/nftData.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/services/providers/web3auth/web3authNotifier.dart';
import 'package:ownerchip_whitelabel/services/providers/websocket/websocketNotifier.dart';
import 'package:ownerchip_whitelabel/services/signature.services.dart';
import 'package:ownerchip_whitelabel/services/wallet.services.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/themes/fontSpecs.dart';
import 'package:ownerchip_whitelabel/utils/globals.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';
import 'package:ownerchip_whitelabel/utils/navigationArguments.dart';
import 'package:ownerchip_whitelabel/widgets/popups/AuthPopup.dart';
import 'package:ownerchip_whitelabel/widgets/popups/CustomPopup.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:ownerchip_whitelabel/widgets/ui/EmailLoginPopup.dart';
import 'package:ownerchip_whitelabel/widgets/ui/PukDisplay.dart';
import 'package:ownerchip_whitelabel/widgets/ui/WalletIcon.dart';
import 'package:reown_appkit/reown_appkit.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web3auth_flutter/enums.dart' as web3auth;
import 'package:web3auth_flutter/input.dart';
import 'package:web3auth_flutter/web3auth_flutter.dart';

import '../../utils/localization.helper.dart';
import '../ui/appBar/AppBarAuthDropDown.dart';

Future<void> walletPopupBuilder(BuildContext context, WidgetRef ref) async {
  final ReownAppKitModal? w3mService = ref.read(w3mServiceProvider);
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
                runSpacing: 12,
                alignment: WrapAlignment.start,
                children: [
                  // Web3auth with Apple
                  if (Platform.isIOS)
                    WalletIcon(
                      iconPath: "assets/images/common/apple.svg",
                      walletName: 'Apple',
                      onTap: () async {
                        await _loginWithWeb3Auth(
                          context,
                          ref: ref,
                          provider: web3auth.Provider.apple,
                          w3mService: w3mService,
                        );
                      },
                      backgroundColor: CustomColors(dotenv.get('APP_ID'))
                          .ownerCardWalletIconBackgroundColor,
                    ),

                  // Web3auth with Google
                  WalletIcon(
                    iconPath: "assets/images/common/google.svg",
                    walletName: 'Google',
                    onTap: () async {
                      await _loginWithWeb3Auth(
                        context,
                        ref: ref,
                        provider: web3auth.Provider.google,
                        w3mService: w3mService,
                      );
                    },
                    backgroundColor: CustomColors(dotenv.get('APP_ID'))
                        .ownerCardWalletIconBackgroundColor,
                  ),
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

                  // Certificate Card
                  // if (dotenv.get("IS_INTERNAL") == "true")
                  //   WalletIcon(
                  //     iconPath:
                  //         "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/ownercard_logo.png",
                  //     walletName: context.loc.certificatecard,
                  //     onTap: () async {
                  //       onCertificateCardLogin(
                  //         ref,
                  //         context,
                  //         false,
                  //       );
                  //     },
                  //     backgroundColor: CustomColors(dotenv.get('APP_ID'))
                  //         .ownerCardWalletIconBackgroundColor,
                  //   ),
                  WalletIcon(
                    iconPath:
                        "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/walletconnect.png",
                    walletName: 'WalletConnect',
                    onTap: () async {
                      Navigator.pop(context);

                      if (w3mService?.isConnected ?? false) {
                        await w3mService?.disconnect();
                        await Future.delayed(const Duration(seconds: 1));
                      }
                      
                      await w3mService?.openModalView();
                      if (ref.read(wcSessionProvider) != null) {
                        authPopupBuilder(
                          navigatorKey.currentContext!,
                          ref,
                          w3mService!,
                          "WalletConnect",
                        ).then((e) {
                          if (e == null || e == false) {
                            w3mService.disconnect();
                          }
                        });
                      }
                    },
                    backgroundColor: CustomColors(dotenv.get('APP_ID'))
                        .ownerCardWalletIconBackgroundColor,
                  ),
                  WalletIcon(
                    walletName: 'Email',
                    icon: Icon(
                      Icons.email,
                      color: CustomColors(dotenv.get('APP_ID')).secondaryColor,
                    ),
                    onTap: () async {
                      _enterEmailPopup(context, ref).then((email) {
                        if (email != null) {
                          _loginWithWeb3Auth(
                            context,
                            ref: ref,
                            provider: web3auth.Provider.email_passwordless,
                            w3mService: w3mService,
                            email: email,
                          );
                        }
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

Future<String?> _enterEmailPopup(BuildContext context, WidgetRef ref) async {
  return showDialog<String?>(
    context: context,
    builder: (BuildContext context) {
      return const EmailLoginPopup();
    },
  );
}

Future<void> _loginWithWeb3Auth(
  BuildContext context, {
  required web3auth.Provider provider,
  required WidgetRef ref,
  ReownAppKitModal? w3mService,
  String? email,
}) async {
  Navigator.pop(context);
  await Web3AuthFlutter.login(
    LoginParams(
      loginProvider: provider,
      extraLoginOptions: ExtraLoginOptions(
        login_hint: email,
      ),
    ),
  ).then((e) async {
    talker.log("Web3Auth login successful: $e");
    final Web3AuthNotifier web3AuthNotifier =
        ref.read(web3AuthNotifierProvider.notifier);

    //set session and wallet type provider
    web3AuthNotifier.setWeb3AuthResponse(e);
    ref.read(walletTypeProvider.notifier).state =
        walletConfig[EWalletType.web3auth];

    //store session and wallet type
    final storage = await SharedPreferences.getInstance();
    await storage.setString('walletType',
        jsonEncode(walletConfig[EWalletType.web3auth]!.toJson()));

    // Store web3auth login timestamp for session expiration check
    final loginTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await storage.setInt('web3authLoginTime', loginTime);

    final userWalletAddress = EthPrivateKey.fromHex(e.privKey!).address;
    ref.read(userAddressProvider.notifier).state = userWalletAddress;

    // Auto-sign and get JWT without showing any popup —
    // web3auth gives us the private key directly so no user interaction needed.
    final walletType = walletConfig[EWalletType.web3auth]!;
    final sessionId = await BackendAuth.getSessionId();
    final String message =
        "Sign this message to confirm that you are the owner of your wallet (SessionId: $sessionId)";
    final siweMessage = BackendAuth.createSiweMessage(
      address: userWalletAddress,
      statement: message,
      nonce: sessionId,
    );

    late final JwtToken token;
    late final MsgSignature signature;
    try {
      final hexSignature = await sendPersonalSignRequest(
        ref,
        siweMessage[1],
        userWalletAddress,
        walletType,
        siweMessage: true,
      );
      final jwt = await BackendAuth.validateSiwe(
        message: siweMessage[0],
        signature: hexSignature,
      );
      token = JwtToken.decode(jwt);
      signature = hexSignatureToRSV(hexSignature);
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      talker.error('Web3Auth: error during auto-sign', e, st);
      final ctx = navigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          returnSnackBarWidget(
              ctx.loc.errorHeadingSnackBar, ctx.loc.errorConnectingWallet, 'error'),
        );
      }
      return;
    }

    // Recreate services with the new JWT so authenticated endpoints work
    Backend.recreateServices(token.raw);

    // Check if there is already a whitelisted wallet linked to this email
    // using a different provider type
    final providersData = await BackendCreator.getWeb3AuthProviders();
    final hasWhitelistedConflict = providersData != null &&
        providersData.providers
            .where((e) => e.providerType != provider.name)
            .any((p) => p.isWhitelisted);

    if (hasWhitelistedConflict) {
      final ctx = navigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        await showExistingAccountDialog(ctx, ref);
      }
      return;
    }

    // Update web3auth profile data on the backend
    try {
      final data = await Web3AuthFlutter.getUserInfo();
      final payload = UpdateWeb3AuthDataPayload(
        name: data.name,
        email: data.email,
        picture: data.profileImage,
        providerType: data.typeOfLogin ?? "",
      );
      await BackendCreator.updateWeb3AuthData(payload);
    } catch (e, st) {
      talker.error('Web3Auth: error updating profile data', e, st);
    }

    // Build and persist the user session
    final userSession = UserSession(
      sessionId,
      signature,
      userWalletAddress,
      false, // isOwnerCard
      false, // isCertificateCard
      token,
      await BackendFCM.getAndSaveFCMToken(sessionId),
    );

    ref.read(userSessionProvider.notifier).state = userSession;
    ref.read(websocketProvider.notifier).init();
    ref.read(creationsNotifierProvider.notifier).load();
    ref.read(accountDeletionRequestProvider.notifier).refresh();

    final String jsonUserSession = jsonEncode(userSession.toJson());
    storage.setString('userSession', jsonUserSession);
    storage.setString('walletType', jsonEncode(walletType.toJson()));

    ref.refresh(findAllMinterRolesProvider);
    ref.refresh(ocNFTsForOwnerProvider);
    ref.refresh(ocNFTsMintedByUserNotifierProvider);
    ref.refresh(myBalanceNotifierProvider);

    BackendApp.sendAnalyticsTrace(sessionId, "", "LOGIN_SUCCESS", tags: {
      'connectedWallet': userWalletAddress.hex,
      'walletType': walletType.name,
    });

    final ctx = navigatorKey.currentContext;
    if (ctx != null && ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        returnSnackBarWidget(
            ctx.loc.successHeadingSnackbar, ctx.loc.walletIsConnected, 'success'),
      );
    }
  }).catchError((e, st) {
    // ignore
    talker.error(e, st);
  });
}

Future<void> showExistingAccountDialog(
    BuildContext context, WidgetRef ref) async {
  
  await showCustomPopup(
    context,
    context.loc.web3authExistingAccountTitle,
    Column(
      children: [
        Text(
          context.loc.web3authExistingAccountDescription,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          onTap: () async {
            Navigator.of(context).pop();
            await disconnectWallet(ref, context);
          },
          title: context.loc.web3authExistingAccountLogout,
        )
      ],
    ),
    showCloseButton: false
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
