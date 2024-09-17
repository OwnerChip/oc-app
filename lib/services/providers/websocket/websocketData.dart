import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart';

class WebsocketData {
  final Socket? socket;

  bool get connected => socket?.connected ?? false;

  const WebsocketData({
    required this.socket,
  });

  factory WebsocketData.initial() {
    return const WebsocketData(
      socket: null,
    );
  }

  WebsocketData copyWith({
    Socket? socket,
    bool? connected,
  }) {
    return WebsocketData(
      socket: socket ?? this.socket,
    );
  }
}
