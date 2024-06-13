import 'package:json_annotation/json_annotation.dart';

part 'raribleRecipientPayload.g.dart';

@JsonSerializable(explicitToJson: true)
class RaribleRecipientPayload {
  factory RaribleRecipientPayload.fromJson(Map<String, dynamic> json) =>
      _$RaribleRecipientPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$RaribleRecipientPayloadToJson(this);

  final String account;
  final int value;

  const RaribleRecipientPayload({
    required this.account,
    required this.value,
  });
}
