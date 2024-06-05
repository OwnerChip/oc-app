import 'package:json_annotation/json_annotation.dart';

part 'sendAnalyticsPayload.g.dart';

@JsonSerializable(explicitToJson: true)
class SendAnalyticsPayload {
  factory SendAnalyticsPayload.fromJson(Map<String, dynamic> json) =>
      _$SendAnalyticsPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$SendAnalyticsPayloadToJson(this);

  @JsonKey(name: 'case_id')
  final String caseId;

  final String description;

  final String type;

  final String? tags;

  const SendAnalyticsPayload({
    required this.caseId,
    required this.description,
    required this.type,
    required this.tags,
  });
}
