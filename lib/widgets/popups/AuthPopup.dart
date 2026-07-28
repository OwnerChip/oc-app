import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/config/wallets.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/domain/jwt/jwt_token.dart';
import 'package:ownerchip_whitelabel/services/backend/app/backendApp.dart';
import 'package:ownerchip_whitelabel/services/backend/auth/backendAuth.dart';
import 'package:ownerchip_whitelabel/services/backend/backend.services.dart';
import 'package:ownerchip_whitelabel/services/providers/accountDeletionRequest/accountDeletionRequestNotifier.dart';
import 'package:ownerchip_whitelabel/services/providers/collectionsData.dart';
import 'package:ownerchip_whitelabel/services/providers/creations/creationsNotifier.dart';
import 'package:ownerchip_whitelabel/services/providers/myBalance/myBalanceNotifier.dart';
import 'package:ownerchip_whitelabel/services/providers/nftData.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/services/providers/websocket/websocketNotifier.dart';
import 'package:ownerchip_whitelabel/services/signature.services.dart';
import 'package:ownerchip_whitelabel/services/wallet.services.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:reown_appkit/reown_appkit.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/localization.helper.dart';

Future<dynamic> authPopupBuilder(
  BuildContext context,
  WidgetRef ref,
  ReownAppKitModal wc,
  String walletName,
) async {
  return showDialog<dynamic>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
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
              const SizedBox(height: 15),
              Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      color: Colors.green, size: 36),
                  const SizedBox(width: 10),
                  Text(context.loc.walletConnected,
                      style: Theme.of(context).textTheme.displaySmall),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      color: Colors.grey, size: 36),
                  const SizedBox(width: 10),
                  Text(context.loc.walletAuthenticated,
                      style: Theme.of(context).textTheme.displaySmall),
                ],
              ),
              const SizedBox(height: 20),
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
  ReownAppKitModalSession? session = ref.read(wcSessionProvider);
  WalletType? walletType = ref.read(walletTypeProvider);

  if (session == null || walletType == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      returnSnackBarWidget(context.loc.errorHeadingSnackBar,
          context.loc.pleaseTryAgainLater, 'error'),
    );
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context, false);
    }
    return;
  }

  final oldUserSession = ref.read(userSessionProvider);
  String sessionId =
      oldUserSession?.sessionId ?? await BackendAuth.getSessionId();
  final bool isOwnerCard = oldUserSession?.isOwnerCard ?? false;
  final bool isCertificateCard = oldUserSession?.isCertificateCard ?? false;

  late final JwtToken token;
  late final MsgSignature signature;

  try {
    final String message =
        "Sign this message to confirm that you are the owner of your wallet (SessionId: $sessionId)";

    final siweMessage = BackendAuth.createSiweMessage(
      address: userWalletAddress,
      statement: message,
      nonce: sessionId,
    );
    String hexSignature = await sendPersonalSignRequest(
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
    talker.error('Error signing message', e, st);
    throw Exception(context.loc.errorConnectingWallet);
  }

  Backend.recreateServices(token.raw);

  UserSession userSession = UserSession(
    sessionId,
    signature,
    ref.read(userAddressProvider),
    isOwnerCard,
    isCertificateCard,
    token,
  );

  ref.read(userSessionProvider.notifier).state = userSession;
  ref.read(websocketProvider.notifier).init();
  ref.read(creationsNotifierProvider.notifier).load();
  ref.read(accountDeletionRequestProvider.notifier).refresh();

  final SharedPreferences storage = await SharedPreferences.getInstance();
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

  ScaffoldMessenger.of(context).showSnackBar(
    returnSnackBarWidget(context.loc.successHeadingSnackbar,
        context.loc.walletIsConnected, 'success'),
  );

  if (Navigator.of(context).canPop()) {
    Navigator.pop(context, true);
  }
}