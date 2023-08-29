import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/services/backend.services.dart';
import 'package:ownerchip_whitelabel/services/providers.services.dart';
import 'package:ownerchip_whitelabel/services/signature.services.dart';
import 'package:ownerchip_whitelabel/services/wallet.services.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/crypto.dart';
import '../../utils/localization.helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';

Future<void> authPopupBuilder(
    BuildContext context, WidgetRef ref, Web3App wc) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          //border radius
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20.0))),
          title: const Padding(
            padding: EdgeInsets.only(),
            child: Text(
              'Sign in',
              textAlign: TextAlign.center,
            ),
          ),
          titleTextStyle: Theme.of(context).textTheme.displayLarge!,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Confirm your identity by authenticating your wallet.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 15,
              ),
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.green,
                    size: 36,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Text(
                    'Wallet connected',
                    style: Theme.of(context).textTheme.displaySmall,
                  )
                ],
              ),
              SizedBox(
                height: 15,
              ),
              Row(
                children: [
                  //grey circle icon full, not outlined
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.grey,
                    size: 36,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Text(
                    'Wallet authenticated',
                    style: Theme.of(context).textTheme.displaySmall,
                  )
                ],
              ),
              SizedBox(
                height: 20,
              ),
              CustomRoundedButton(
                  text: 'Authenticate',
                  onPressed: () =>
                      onTapAuth(context, 'insert_session_id', ref)),
            ],
          ));
    },
  );
}

Future<void> onTapAuth(
    BuildContext context, String sessionId, WidgetRef ref) async {
  Web3App? wc = ref.read(wcProvider);
  EthereumAddress userWalletAddress = ref.read(userAddressProvider);
  SessionData? session = ref.read(wcSessionProvider);
  WalletType? walletType = ref.read(walletTypeProvider);

  //get sessionid from backend (only if not already set)
  final oldUserSession = ref.read(userSessionProvider);
  String sessionId = oldUserSession?.sessionId ?? await getSessionId();

  String message =
      "Sign this message to confirm that you are the owner of your wallet (SessionId: $sessionId)";

  String hexSignature = await sendPersonalSignRequest(
      message, userWalletAddress, wc!, session!, walletType!);

  MsgSignature signature = hexSignatureToRSV(hexSignature);

  int sevenDaysInSeconds = 60 * 60 * 24 * 7;
  int sessionExpirationDate = await getSessionExpiration(
      sevenDaysInSeconds, sessionId, userWalletAddress, signature);

  UserSession userSession = UserSession(sessionId, signature,
      ref.read(userAddressProvider), sessionExpirationDate);

  ref.read(userSessionProvider.notifier).state = userSession;

  //persist session date
  final SharedPreferences storage = await SharedPreferences.getInstance();
  final String jsonUserSession = jsonEncode(userSession.toJson());
  storage.setString('userSession', jsonUserSession);

  ref.refresh(findAllMinterRolesProvider);

  sendAnalyticsTrace(sessionId, "", "LOGIN_SUCCESS", tags: {
    'connectedWallet': userWalletAddress.toString(),
    'walletType': walletType.toString(),
  });

  //success snackbar
  ScaffoldMessenger.of(context).showSnackBar(
    returnSnackBarWidget(
        context.loc.successHeadingSnackbar, 'Connected wallet.', 'success'),
  );

  //navigate back
  Navigator.pop(context);
}
