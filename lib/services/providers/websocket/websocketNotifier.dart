import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/services/backend/auth/backendAuth.dart';
import 'package:ownerchip_whitelabel/services/nfc.services.dart';
import 'package:ownerchip_whitelabel/services/providers/nftData.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/services/providers/websocket/types/websocketPingRequest.dart';
import 'package:ownerchip_whitelabel/services/providers/websocket/types/websocketRequest.dart';
import 'package:ownerchip_whitelabel/services/providers/websocket/websocketData.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart';
import "package:collection/collection.dart";

class WebsocketNotifier extends Notifier<WebsocketData> {
  @override
  WebsocketData build() {
    return WebsocketData.initial();
  }

  Timer? _pingTimer;

  Future<void> _emit(
    WebsocketRequest request,
  ) async {
    try {
      if (state.socket != null && state.socket!.connected) {
        state.socket?.emit(
          request.type,
          request.toJson(),
        );
      }
    } catch (e, s) {
      talker.error(e, s);
    }
  }

  void onResumedFromBackground() {
    try {
      final socket = state.socket;
      if (socket != null && !socket.connected) {
        init();
        return;
      }
    } catch (e, s) {
      talker.error(e, s);
    }
  }

  Future<bool> init() async {
    final connectionCompleter = Completer<bool>();
    try {
      final session = ref.read(userSessionProvider);
      talker.info("WebsocketNotifier.init");

      if (session == null) {
        talker.error("WebsocketNotifier.init: no session");
        return false;
      }

      state.socket?.dispose();

      final url = (dotenv.get('IS_INTERNAL') == 'true'
              ? dotenv.get('OC_BACKEND_URL_TEST')
              : dotenv.get('OC_BACKEND_URL'))
          .replaceAll("https", "wss")
          .replaceAll("http", "ws");
      state = state.copyWith(
        socket: io(
          url,
          OptionBuilder()
              .setAuth(
                {
                  "token": session.jwt.raw,
                },
              )
              .setTransports(['websocket'])
              .setReconnectionAttempts(9999)
              .setReconnectionDelay(1000)
              .setReconnectionDelayMax(5000)
              .build(),
        ),
      );

      talker.info("WebsocketNotifier.init: connecting to $url");

      onConnect(_) {
        state = state.copyWith(connecting: false);
        talker.info("WebsocketNotifier.init: connected to $url");
        connectionCompleter.complete(true);
      }

      state.socket?.onConnect(onConnect);

      onConnectError(data) {
        talker
            .error("WebsocketNotifier.init: error connecting to $url \n $data");
        state = state.copyWith(connecting: false);
        connectionCompleter.complete(false);
      }

      state.socket?.onConnectError(onConnectError);

      onAny(String event, data) async {
        talker.info("WebsocketNotifier.init: received $event \n $data");

        final eventEnum = websocketRequestTypes.entries
            .firstWhereOrNull((element) => element.value == event)
            ?.key;

        if (eventEnum == null) {
          talker.error("WebsocketNotifier.init: received unknown event $event");
          return;
        }

        switch (eventEnum) {
          case WebsocketRequestType.ping:
            talker.info("WebsocketNotifier.init: received ping");
            break;
          case WebsocketRequestType.qrCodeLoginConfirm:
            talker.info("WebsocketNotifier.init: received qrCodeLoginConfirm");
            break;
          case WebsocketRequestType.newJwt:
            talker.info("WebsocketNotifier.init: received newJwt");
            final storage = await SharedPreferences.getInstance();

            //remove session and wallet type from storage
            storage.remove('walletType');
            storage.remove('userSession');
            ref.read(w3mServiceProvider)?.disconnect();
            await BackendAuth.initGuestSession();

            break;
          case WebsocketRequestType.refreshGallery:
            talker.info("WebsocketNotifier.init: received refreshGallery");
            ref.invalidate(ocNFTsForOwnerProvider);
            ref.invalidate(ocNFTsMintedByUserNotifierProvider);
            break;
        }
      }

      state.socket?.onAny(onAny);

      onDisconnect(_) {
        state = state.copyWith(connecting: false);
        talker.info("WebsocketNotifier.init: disconnected from $url");

        // remove all listeners
        state.socket?.off('connect');
        state.socket?.off('connect_error');
        state.socket?.off('connect_timeout');
        state.socket?.off('connecting');
        state.socket?.off('disconnect');
        state.socket?.offAny();

        // reconnect
        init();
      }

      state.socket?.onDisconnect(onDisconnect);

      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(
        const Duration(seconds: 15),
        (_) {
          _emit(
            WebsocketPingRequest(),
          );
        },
      );

      state.socket?.connect();
      state = state.copyWith(connecting: true);
    } catch (e, s) {
      talker.error(e, s);
    }

    return connectionCompleter.future;
  }

  void disconnect() {
    if (state.socket != null) {
      state.socket?.disconnect();
      state = WebsocketData.initial();
    }
  }
}

final websocketProvider = NotifierProvider<WebsocketNotifier, WebsocketData>(
  WebsocketNotifier.new,
);
