import 'package:json_annotation/json_annotation.dart';
import 'package:ownerchip_whitelabel/services/providers/websocket/types/websocketRequest.dart';

part 'websocketPingRequest.g.dart';

@JsonSerializable(explicitToJson: true)
class WebsocketPingRequest extends WebsocketRequest {
  factory WebsocketPingRequest.fromJson(Map<String, dynamic> json) =>
      _$WebsocketPingRequestFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$WebsocketPingRequestToJson(this);

  WebsocketPingRequest() : super(type: WebsocketRequestType.ping.str);
}
