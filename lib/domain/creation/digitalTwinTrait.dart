
import 'package:json_annotation/json_annotation.dart';

part 'digitalTwinTrait.g.dart';

@JsonSerializable(explicitToJson: true)
class DigitalTwinTrait {

	factory DigitalTwinTrait.fromJson(Map<String, dynamic> json) => _$DigitalTwinTraitFromJson(json);
	Map<String, dynamic> toJson( ) => _$DigitalTwinTraitToJson(this);

  @JsonKey(name: "trait_type")
  final String traitType;

  final String value;

  const DigitalTwinTrait({
    required this.traitType,
    required this.value,
  });

}