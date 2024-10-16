import 'package:json_annotation/json_annotation.dart';

part 'cardInitPayload.g.dart';

@JsonSerializable(explicitToJson: true)
class CardInitPayload {
  factory CardInitPayload.fromJson(Map<String, dynamic> json) =>
      _$CardInitPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$CardInitPayloadToJson(this);

  final String id;
  final bool isCertificateCard;

  final String ocInternalPassword;

  const CardInitPayload({
    required this.id,
    this.isCertificateCard = false,
    required this.ocInternalPassword,
  });
}
