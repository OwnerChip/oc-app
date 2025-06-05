import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart';

class WebsocketData {
  final Socket? socket;

  bool get connected => socket?.connected ?? false;

  final bool connecting;

  const WebsocketData({
    required this.socket,
    required this.connecting
  });

  factory WebsocketData.initial() {
    return const WebsocketData(
      socket: null,
      connecting: false
    );
  }

  WebsocketData copyWith({
    Socket? socket,
    bool? connecting
  }) {
    return WebsocketData(
      socket: socket ?? this.socket,
      connecting: connecting ?? this.connecting
    );
  }
}
