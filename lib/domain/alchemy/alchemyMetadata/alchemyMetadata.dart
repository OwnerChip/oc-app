import 'package:json_annotation/json_annotation.dart';

part 'alchemyMetadata.g.dart';

@JsonSerializable(explicitToJson: true)
class Metadata {
  factory Metadata.fromJson(Map<String, dynamic> json) =>
      _$MetadataFromJson(json);

  Map<String, dynamic> toJson() => _$MetadataToJson(this);

  String name;
  String image;
  List<dynamic>
      traits; // Using dynamic since the structure of traits is not specified

  Metadata({
    required this.name,
    required this.image,
    required this.traits,
  });
}
