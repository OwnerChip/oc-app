import 'package:json_annotation/json_annotation.dart';

part 'websocketRequest.g.dart';

@JsonSerializable(explicitToJson: true)
class WebsocketRequest {
  factory WebsocketRequest.fromJson(
    Map<String, dynamic> json,
  ) =>
      _$WebsocketRequestFromJson(json);

  Map<String, dynamic> toJson() => _$WebsocketRequestToJson(this);

  final String type;

  const WebsocketRequest({
    required this.type,
  });
}

enum WebsocketRequestType { ping }

extension WebsocketRequestTypeExtension on WebsocketRequestType {
  String get str => websocketRequestTypes[this]!;
}

final websocketRequestTypes = {
  WebsocketRequestType.ping: '1',
};
