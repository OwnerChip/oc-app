import 'package:json_annotation/json_annotation.dart';

part 'sendGaslessRequestPayload.g.dart';

@JsonSerializable(explicitToJson: true)
class SendGaslessRequestPayload {
  factory SendGaslessRequestPayload.fromJson(Map<String, dynamic> json) =>
      _$SendGaslessRequestPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$SendGaslessRequestPayloadToJson(this);

  final String txSignature;
  final String metaTxAgreementId;
  final Map<String, dynamic> txRequest;

  const SendGaslessRequestPayload({
    required this.txSignature,
    required this.metaTxAgreementId,
    required this.txRequest,
  });
}
