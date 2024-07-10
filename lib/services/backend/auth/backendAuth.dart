import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/config/wallets.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/domain/fcm/fcm_token.dart';
import 'package:ownerchip_whitelabel/domain/jwt/jwt_token.dart';
import 'package:ownerchip_whitelabel/domain/walletSignature/walletSignature.dart';
import 'package:ownerchip_whitelabel/services/backend/auth/backendAuthService.dart';
import 'package:ownerchip_whitelabel/services/backend/auth/payloads/getSessionExpirationPayload.dart';
import 'package:ownerchip_whitelabel/services/backend/auth/payloads/validateSiwePayload.dart';
import 'package:ownerchip_whitelabel/services/backend/backend.services.dart';
import 'package:ownerchip_whitelabel/services/backend/fcm/backendFcm.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:sentry/sentry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

abstract class BackendAuth extends Backend {
  static int nowPlusThreeHours() =>
      DateTime.now()
          .add(
            const Duration(
              hours: 3,
            ),
          )
          .millisecondsSinceEpoch ~/
      1000;

  /// returns a tuple of [Map, String].
  /// Map: the message to be signed.
  /// String: SIWE message.
  static List<dynamic> createSiweMessage({
    required EthereumAddress address,
    required String statement,
    required String nonce,
    int chainId = 1,
  }) {
    const version = 1;
    // Address must be EIP55 compliant, if using web3dart, use the hexEip55 method.
    DateTime now = DateTime.now();
    int millisecondsSinceEpoch = now.millisecondsSinceEpoch;
    String iso8601 = DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch)
        .toIso8601String();
    // Remove microseconds from the ISO 8601 string
    int indexOfDot = iso8601.indexOf('.');
    String iso8601WithoutMicroseconds =
        '${iso8601.substring(0, indexOfDot + 4)}Z';

    final domain = dotenv.get('BITRISEIO_PACKAGE_NAME');
    final uri = "${dotenv.get("APP_ID")}://sign-in";

    final message =
        "$domain wants you to sign in with your Ethereum account:\n${address.hexEip55}\n\n$statement\n\nURI: $uri\nVersion: $version\nChain ID: $chainId\nNonce: $nonce\nIssued At: $iso8601WithoutMicroseconds";
    return [
      {
        "address": address.hexEip55,
        "chainId": chainId,
        "domain": domain,
        "issuedAt": iso8601WithoutMicroseconds,
        "statement": statement,
        "nonce": nonce,
        "uri": uri,
        "version": version.toString(),
      },
      message
    ];
  }

  static Future<void> initGuestSession() async {
    try {
      final storage = await SharedPreferences.getInstance();

      final cached = storage.getString("guestSession");

      // create a guest session
      if (cached != null &&
          JwtToken.decode(cached).exp > BackendAuth.nowPlusThreeHours()) {
        talker
            .info("recreating services with cached guest session \n $cached");
        final jwt = JwtToken.decode(cached);
        Backend.recreateServices(jwt.raw);
      } else {
        talker.info("creating new guest session");
        final newJwt =
        JwtToken.decode(await BackendAuth.createGuestSession());
        storage.setString("guestSession", newJwt.raw);
        print(newJwt.exp);
        Backend.recreateServices(newJwt.raw);
        talker.info("new guest session created \n $newJwt");
      }
    } catch (e) {
      Sentry.captureException(
        e,
      );
      talker.error(
        e,
      );
      talker.info(
          "error creating guest session, recreating services with no jwt");
      Backend.recreateServices(null);
    }
  }

  static Future<String> createGuestSession() async {
    return BackendAuthService.instance.createGuestSession().catchError((e) {
      Sentry.captureException(
        e,
      );
      talker.error(
        e,
      );

      throw e;
    });
  }

  /// validate a SIWE message
  /// returns JWT token
  static Future<String> validateSiwe({
    required Map<String, dynamic> message,
    required String signature,
  }) async {
    return BackendAuthService.instance
        .validateSiwe(
      body: ValidateSiwePayload(
        message: message,
        signature: signature,
      ),
    )
        .catchError((e) {
      Sentry.captureException(
        e,
      );
      talker.error(
        e,
      );

      throw e;
    });
  }

  /// get session expiration time
  static Future<dynamic> getSessionExpiration(
      int sessionDuration,
      String sessionId,
      EthereumAddress userWalletAddress,
      MsgSignature signature) async {
    return int.parse(
      await BackendAuthService.instance
          .getSessionExpiration(
        expiration: sessionDuration,
        payload: GetSessionExpirationPayload(
          sessionId: sessionId,
          userWalletSignature: WalletSignature.fromMsgSignature(
            signature,
          ),
          walletAddress: userWalletAddress.hex,
        ),
      )
          .catchError((e) {
        Sentry.captureException(
          e,
        );
        talker.error(
          e,
        );

        throw e;
      }),
    );
  }

  /// save a userSession of a OwnerCard
  static Future<void> saveUserSession(
    String sessionId,
    EthereumAddress cardWalletAddress,
    MsgSignature signature,
    WidgetRef ref,
    String? jwt,
  ) async {
    late JwtToken jwtToken;

    if (jwt == null) {
      int sevenDaysInSeconds = 60 * 60 * 24 * 7;
      int sessionExpirationDate = await getSessionExpiration(
          sevenDaysInSeconds, sessionId, cardWalletAddress, signature);

      jwtToken = JwtToken(
        raw: "",
        walletAddress: cardWalletAddress.hex,
        sessionId: sessionId,
        role: "user",
        iat: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        exp: sessionExpirationDate ~/ 1000,
      );
    } else {
      jwtToken = JwtToken.decode(jwt);
    }

    ref.read(userAddressProvider.notifier).state = cardWalletAddress;
    ref.read(walletTypeProvider.notifier).state =
        walletConfig[EWalletType.ownerCard];
    const isOwnerCard = true;

    Backend.recreateServices(jwtToken.raw);

    UserSession userSession = UserSession(
      sessionId,
      signature,
      ref.read(userAddressProvider),
      isOwnerCard,
      jwtToken,
      await BackendFCM.getAndSaveFCMToken(sessionId)
    );

    ref.read(userSessionProvider.notifier).state = userSession;
    ref.read(walletTypeProvider.notifier).state =
        walletConfig[EWalletType.ownerCard];

    //persist session date
    final SharedPreferences storage = await SharedPreferences.getInstance();
    storage.setString(
      'userSession',
      jsonEncode(userSession.toJson()),
    );
    storage.setString(
      'walletType',
      jsonEncode(walletConfig[EWalletType.ownerCard]!.toJson()),
    );
  }

  static Future<bool> terminateSession() async {
    bool success = true;
    await BackendAuthService.instance.terminateSession().catchError((e) {
      Sentry.captureException(
        e,
      );
      talker.error(
        e,
      );
      success = false;
    });

    return success;
  }

  // This function requests a Session Id from the backend
  static Future<String> getSessionId() async {
    final service = BackendAuthService.instance;

    return service.getSessionId().catchError((e) {
      Sentry.captureException(
        e,
      );
      talker.error(
        e,
      );

      return makeRandomInt().toString();
    });
  }
}
