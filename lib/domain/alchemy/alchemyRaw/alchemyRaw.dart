import 'package:json_annotation/json_annotation.dart';
import 'package:ownerchip_whitelabel/domain/alchemy/alchemyMetadata/alchemyMetadata.dart';

part 'alchemyRaw.g.dart';

@JsonSerializable(explicitToJson: true)
class AlchemyRaw {
  factory AlchemyRaw.fromJson(Map<String, dynamic> json) =>
      _$AlchemyRawFromJson(json);

  Map<String, dynamic> toJson() => _$AlchemyRawToJson(this);

  String tokenUri;
  Metadata metadata;
  dynamic error; // Using dynamic since the type is not specified

  AlchemyRaw({
    required this.tokenUri,
    required this.metadata,
    this.error,
  });
}
