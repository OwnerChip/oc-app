import 'package:json_annotation/json_annotation.dart';

part 'qrcodeLoginConfirmPayload.g.dart';

@JsonSerializable(explicitToJson: true)
class QrCodeLoginConfirmPayload {
  factory QrCodeLoginConfirmPayload.fromJson(Map<String, dynamic> json) =>
      _$QrCodeLoginConfirmPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$QrCodeLoginConfirmPayloadToJson(this);

  final String sessionId;
  final String socketId;

  const QrCodeLoginConfirmPayload({
    required this.sessionId,
    required this.socketId,
  });
}
