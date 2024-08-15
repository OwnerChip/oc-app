import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:ownerchip_whitelabel/services/providers/websocket/types/websocketPingRequest.dart';
import 'package:ownerchip_whitelabel/services/providers/websocket/types/websocketRequest.dart';
import 'package:ownerchip_whitelabel/services/providers/websocket/websocketData.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';
import 'package:socket_io_client/socket_io_client.dart';

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
      if (state.socket == null) {
        return;
      }

      state.socket?.emit(
        request.type,
        request.toJson(),
      );
    } catch (e, s) {
      talker.error(e, s);
    }
  }

  void init() {
    try {
      final session = ref.read(userSessionProvider);
      talker.info("WebsocketNotifier.init");

      if (session == null) {
        return;
      }

      if (state.socket != null) {
        talker.info("WebsocketNotifier.init: disconnecting");
        state.socket?.disconnect();
        state = state.copyWith(socket: null, connected: false);
      }

      final url = dotenv
          .get("OC_BACKEND_URL_TEST")
          .replaceAll("https", "wss")
          .replaceAll("http", "ws");
      final socket = io(
        url,
        OptionBuilder()
            .setAuth(
              {
                "token": session.jwt.raw,
              },
            )
            .setTransports(['websocket'])
            .build(),
      );
      talker.info("WebsocketNotifier.init: connecting to $url");

      socket.onConnect((_) {
        state = state.copyWith(socket: socket, connected: true);
        talker.info("WebsocketNotifier.init: connected to $url");
      });

      socket.onDisconnect((_) {
        state = state.copyWith(socket: null, connected: false);
        talker.info("WebsocketNotifier.init: disconnected from $url");
      });

      socket.onConnectError((data) {
        talker.error(
            "WebsocketNotifier.init: error connecting to $url \n $data");
      });

      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(
        const Duration(seconds: 15),
        (_) {
          _emit(
            WebsocketPingRequest(),
          );
        },
      );

      socket.connect();
      talker.info("WebsocketNotifier.init: connecting to $url");
    } catch (e, s) {
      talker.error(e, s);
    }
  }

  void disconnect() {
    if (state.socket != null) {
      state.socket?.disconnect();
      state = state.copyWith(socket: null, connected: false);
    }
  }
}

final websocketProvider = NotifierProvider<WebsocketNotifier, WebsocketData>(
  WebsocketNotifier.new,
);
