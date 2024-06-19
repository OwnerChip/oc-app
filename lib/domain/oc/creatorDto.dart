import 'package:json_annotation/json_annotation.dart';


part 'creatorDto.g.dart';

@JsonSerializable(explicitToJson: true)
class CreatorDto {

	factory CreatorDto.fromJson(Map<String, dynamic> json) => _$CreatorDtoFromJson(json);
	Map<String, dynamic> toJson( ) => _$CreatorDtoToJson(this);

  final String address;
  final String name;
  final String affiliation;
  final String email;

  @JsonKey(name: "is_ownercard")
  final bool isOwnercard;

  const CreatorDto({
    required this.address,
    required this.name,
    required this.affiliation,
    required this.email,
    required this.isOwnercard,
  });
}