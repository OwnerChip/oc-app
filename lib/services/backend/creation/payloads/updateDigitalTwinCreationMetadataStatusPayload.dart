
import 'package:json_annotation/json_annotation.dart';
import 'package:ownerchip_whitelabel/domain/creation/digitalTwinMetadata.dart';

part 'updateDigitalTwinCreationMetadataStatusPayload.g.dart';

@JsonSerializable(
  explicitToJson: true
)
class UpdateDigitalTwinCreationMetadataStatusPayload {

	factory UpdateDigitalTwinCreationMetadataStatusPayload.fromJson(Map<String, dynamic> json) => _$UpdateDigitalTwinCreationMetadataStatusPayloadFromJson(json);
	Map<String, dynamic> toJson( ) => _$UpdateDigitalTwinCreationMetadataStatusPayloadToJson(this);

  final DigitalTwinCreationMetadataStatus status;

  const UpdateDigitalTwinCreationMetadataStatusPayload({
    required this.status,
  });


}

