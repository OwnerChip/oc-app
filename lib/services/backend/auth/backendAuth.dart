import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/config/wallets.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/domain/walletSignature/walletSignature.dart';
import 'package:ownerchip_whitelabel/services/backend/auth/backendAuthService.dart';
import 'package:ownerchip_whitelabel/services/backend/auth/payloads/getSessionExpirationPayload.dart';
import 'package:ownerchip_whitelabel/services/backend/backend.services.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:sentry/sentry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

abstract class BackendAuth extends Backend {
  /// get session expiration time
  static Future<dynamic> getSessionExpiration(
      int sessionDuration,
      String sessionId,
      EthereumAddress userWalletAddress,
      MsgSignature signature) async {
    final service = BackendAuthService.instance;
    try {
      return int.parse(
        await service.getSessionExpiration(
          expiration: sessionDuration,
          payload: GetSessionExpirationPayload(
            sessionId: sessionId,
            userWalletSignature: WalletSignature.fromMsgSignature(
              signature,
            ),
            walletAddress: userWalletAddress.hex,
          ),
        ),
      );
    } catch (e, s) {
      await Sentry.captureException(
        e,
        stackTrace: s,
      );
      print(e);
      return 0;
    }
  }

  /// save a userSession of a OwnerCard
  static Future<void> saveUserSession(
      String sessionId,
      EthereumAddress cardWalletAddress,
      MsgSignature signature,
      WidgetRef ref) async {
    int sevenDaysInSeconds = 60 * 60 * 24 * 7;
    int sessionExpirationDate = await getSessionExpiration(
        sevenDaysInSeconds, sessionId, cardWalletAddress, signature);

    ref.read(userAddressProvider.notifier).state = cardWalletAddress;
    ref.read(walletTypeProvider.notifier).state =
        walletConfig[EWalletType.ownerCard];
    const isOwnerCard = true;
    UserSession userSession = UserSession(sessionId, signature,
        ref.read(userAddressProvider), isOwnerCard, sessionExpirationDate);

    ref.read(userSessionProvider.notifier).state = userSession;

    //persist session date
    final SharedPreferences storage = await SharedPreferences.getInstance();
    final String jsonUserSession = jsonEncode(userSession.toJson());
    storage.setString('userSession', jsonUserSession);
  }

  // This function requests a Session Id from the backend
  static Future<String> getSessionId() async {
    final service = BackendAuthService.instance;

    try {
      return service.getSessionId();
    } catch (e, s) {
      await Sentry.captureException(
        e,
        stackTrace: s,
      );
      print(e);
      //fallback!
      return makeRandomInt().toString();
    }
  }
}
