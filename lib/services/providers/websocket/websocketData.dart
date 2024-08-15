import 'package:socket_io_client/socket_io_client.dart';

class WebsocketData {
  final Socket? socket;
  final bool connected;

  const WebsocketData({
    required this.socket,
    required this.connected,
  });

  factory WebsocketData.initial() {
    return const WebsocketData(
      socket: null,
      connected: false,
    );
  }

  WebsocketData copyWith({
    Socket? socket,
    bool? connected,
  }) {
    return WebsocketData(
      socket: socket ?? this.socket,
      connected: connected ?? this.connected,
    );
  }
}
