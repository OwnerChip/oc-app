import 'package:json_annotation/json_annotation.dart';

part 'validateSiwePayload.g.dart';

@JsonSerializable(explicitToJson: true)
class ValidateSiwePayload {

  factory ValidateSiwePayload.fromJson(Map<String, dynamic> json) =>
      _$ValidateSiwePayloadFromJson(json);

  Map<String, dynamic> toJson() => _$ValidateSiwePayloadToJson(this);

  final Map<String, dynamic> message;
  final String signature;

  const ValidateSiwePayload({
    required this.message,
    required this.signature,
  });
}
