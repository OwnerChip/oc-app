import 'package:json_annotation/json_annotation.dart';

part 'restoreDigitalTwinCreationPayload.g.dart';

@JsonSerializable(explicitToJson: true)
class RestoreDigitalTwinCreationPayload {
  factory RestoreDigitalTwinCreationPayload.fromJson(
          Map<String, dynamic> json) =>
      _$RestoreDigitalTwinCreationPayloadFromJson(json);

  Map<String, dynamic> toJson() =>
      _$RestoreDigitalTwinCreationPayloadToJson(this);

  final String tokenId;

  const RestoreDigitalTwinCreationPayload({
    required this.tokenId,
  });
}
