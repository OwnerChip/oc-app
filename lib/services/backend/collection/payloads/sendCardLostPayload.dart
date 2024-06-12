import 'package:json_annotation/json_annotation.dart';

part 'sendCardLostPayload.g.dart';

@JsonSerializable(explicitToJson: true)
class SendCardLostPayload {
  factory SendCardLostPayload.fromJson(Map<String, dynamic> json) =>
      _$SendCardLostPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$SendCardLostPayloadToJson(this);

  final String name;
  final String email;
  final String telNr;
  final String sessionId;
  final String chipAddress;
  final Map<String, dynamic> chipSignature;

  const SendCardLostPayload({
    required this.name,
    required this.email,
    required this.telNr,
    required this.sessionId,
    required this.chipAddress,
    required this.chipSignature,
  });
}
