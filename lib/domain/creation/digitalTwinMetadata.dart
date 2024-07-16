import 'package:json_annotation/json_annotation.dart';
import 'package:ownerchip_whitelabel/domain/collection/ocCollection.dart';
import 'package:ownerchip_whitelabel/domain/converters/dateTimeJsonConverter.dart';

part 'digitalTwinMetadata.g.dart';

@JsonSerializable(explicitToJson: true)
class DigitalTwinMetadata {

  factory DigitalTwinMetadata.fromJson(Map<String, dynamic> json) =>
      _$DigitalTwinMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$DigitalTwinMetadataToJson(this);

  final int id;
  final String collectionId;

  final OCCollection collection;
  final String creatorId;
  final String twinTokenMetadataCID;
  final String voucherTokenMetadataCID;
  final Map<String, String> traits;
  final String title;
  final String description;

  final DigitalTwinCreationMetadataStatus status;

  @DateTimeJsonConverter()
  final DateTime createdAt;

  const DigitalTwinMetadata({
    required this.id,
    required this.collectionId,
    required this.collection,
    required this.creatorId,
    required this.twinTokenMetadataCID,
    required this.voucherTokenMetadataCID,
    required this.traits,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
  });
}

enum DigitalTwinCreationMetadataStatus {

  @JsonValue("PENDING")
  pending,

  @JsonValue("REJECTED")
  rejected,

  @JsonValue("MINTED")
  minted,
}
