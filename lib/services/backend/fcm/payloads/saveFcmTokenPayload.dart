import 'package:json_annotation/json_annotation.dart';

part 'saveFcmTokenPayload.g.dart';

@JsonSerializable(explicitToJson: true)
class SaveFCMTokenPayload {

  factory SaveFCMTokenPayload.fromJson(Map<String, dynamic> json) =>
      _$SaveFCMTokenPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$SaveFCMTokenPayloadToJson(this);

  final String token;
  final String sessionId;

  const SaveFCMTokenPayload({
    required this.token,
    required this.sessionId,
  });
}
