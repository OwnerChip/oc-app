import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ownerchip_whitelabel/services/backend.services.dart';
import 'package:ownerchip_whitelabel/services/providers/nftData.dart';
import 'package:ownerchip_whitelabel/services/providers/web3auth/web3authNotifier.dart';
import 'package:ownerchip_whitelabel/services/providers/web3auth/web3authNotifierData.dart';
import 'package:ownerchip_whitelabel/services/signature.services.dart';
import 'package:ownerchip_whitelabel/services/wallet.services.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3modal_flutter/services/w3m_service/models/w3m_session.dart';
import '../../utils/localization.helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/services/providers/collectionsData.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';

Future<void> authPopupBuilder(
  BuildContext context,
  WidgetRef ref,
) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          //border radius
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20.0))),
          title: Padding(
            padding: const EdgeInsets.only(),
            child: Text(
              context.loc.login,
              textAlign: TextAlign.center,
            ),
          ),
          titleTextStyle: Theme.of(context).textTheme.displayLarge!,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.loc.confirmYourIdentity,
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
                    context.loc.walletConnected,
                    style: Theme.of(context).textTheme.displaySmall,
                  )
                ],
              ),
              const SizedBox(
                height: 15,
              ),
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.grey,
                    size: 36,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Text(
                    context.loc.walletAuthenticated,
                    style: Theme.of(context).textTheme.displaySmall,
                  )
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              CustomRoundedButton(
                  text: context.loc.authenticate,
                  onPressed: () {
                    onTapAuth(context, 'insert_session_id', ref);
                  }),
            ],
          ));
    },
  );
}

Future<void> onTapAuth(
  BuildContext context,
  String sessionId,
  WidgetRef ref,
) async {
  EthereumAddress userWalletAddress = ref.read(userAddressProvider);
  W3MSession? session = ref.read(wcSessionProvider);
  Web3AuthNotifierData web3AuthData = ref.read(web3AuthNotifierProvider);
  WalletType? walletType = ref.read(walletTypeProvider);

  if ((session == null && web3AuthData.web3AuthResponse == null) ||
      walletType == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      returnSnackBarWidget(context.loc.errorHeadingSnackBar,
          context.loc.pleaseTryAgainLater, 'error'),
    );
    //remove auth popup
    Navigator.pop(context);
    return;
  }

  //get sessionid from backend (only if not already set)
  final oldUserSession = ref.read(userSessionProvider);
  String sessionId = oldUserSession?.sessionId ?? await getSessionId();
  bool isOwnerCard = oldUserSession?.isOwnerCard ?? false;

  String message =
      "Sign this message to confirm that you are the owner of your wallet (SessionId: $sessionId)";

  String hexSignature = await sendPersonalSignRequest(
      ref, message, userWalletAddress, session, web3AuthData, walletType);

  MsgSignature signature = hexSignatureToRSV(hexSignature);

  int sevenDaysInSeconds = 60 * 60 * 24 * 7;
  int sessionExpirationDate = await getSessionExpiration(
      sevenDaysInSeconds, sessionId, userWalletAddress, signature);

  UserSession userSession = UserSession(sessionId, signature,
      ref.read(userAddressProvider), isOwnerCard, sessionExpirationDate);

  ref.read(userSessionProvider.notifier).state = userSession;

  //persist session date
  final SharedPreferences storage = await SharedPreferences.getInstance();
  final String jsonUserSession = jsonEncode(userSession.toJson());
  storage.setString('userSession', jsonUserSession);

  await ref.refresh(findAllMinterRolesProvider);
  await ref.refresh(getOcNftsForOwner);
  await ref.refresh(getOcNftsMintedByUser);

  sendAnalyticsTrace(sessionId, "", "LOGIN_SUCCESS", tags: {
    'connectedWallet': userWalletAddress.hex,
    'walletType': walletType.name,
  });

  //success snackbar
  ScaffoldMessenger.of(context).showSnackBar(
    returnSnackBarWidget(context.loc.successHeadingSnackbar,
        context.loc.walletIsConnected, 'success'),
  );

  Navigator.pop(context);
}
