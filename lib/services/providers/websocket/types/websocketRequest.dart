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

  @DynamicOneSideJsonConverter()
  final dynamic data;

  const WebsocketRequest({
    required this.type,
    required this.data,
  });
}

enum WebsocketRequestType { ping }

extension WebsocketRequestTypeExtension on WebsocketRequestType {
  String get str => websocketRequestTypes[this]!;
}

final websocketRequestTypes = {
  WebsocketRequestType.ping: '1',
};

class DynamicOneSideJsonConverter<T> implements JsonConverter<T, Object?> {
  const DynamicOneSideJsonConverter();

  @override
  T fromJson(Object? json) {
    throw Exception('not implemented');
  }

  @override
  Object? toJson(T object) => (object as dynamic).toJson();
}
