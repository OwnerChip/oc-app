import 'package:json_annotation/json_annotation.dart';

part 'raribleRequestConfig.g.dart';

@JsonSerializable(explicitToJson: true)
class RaribleRequestConfig {
  factory RaribleRequestConfig.fromJson(Map<String, dynamic> json) =>
      _$RaribleRequestConfigFromJson(json);

  Map<String, dynamic> toJson() => _$RaribleRequestConfigToJson(this);

  final String method;
  final String endpoint;
  final Map<String, dynamic> body;
  final Map<String, String> headers;

  const RaribleRequestConfig({
    required this.method,
    required this.endpoint,
    required this.body,
    required this.headers,
  });
}
