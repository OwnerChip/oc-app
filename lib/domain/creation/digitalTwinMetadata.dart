import 'package:json_annotation/json_annotation.dart';
import 'package:ownerchip_whitelabel/domain/collection/ocCollection.dart';
import 'package:ownerchip_whitelabel/domain/converters/dateTimeJsonConverter.dart';
import 'package:ownerchip_whitelabel/domain/creation/digitalTwinTrait.dart';

part 'digitalTwinMetadata.g.dart';

@JsonSerializable(explicitToJson: true)
class DigitalTwinMetadata {
  factory DigitalTwinMetadata.fromJson(Map<String, dynamic> json) =>
      _$DigitalTwinMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$DigitalTwinMetadataToJson(this);

  final String id;
  final String collectionId;

  final OCCollection collection;
  final String creatorId;

  final String? imageCID;
  final String? twinTokenMetadataCID;
  final List<DigitalTwinTrait> traits;
  final String title;
  final String description;
  final String? imageLink;

  @JsonKey(unknownEnumValue: DigitalTwinCreationMetadataStatus.unknown)
  final DigitalTwinCreationMetadataStatus status;

  @DateTimeJsonConverter()
  final DateTime createdAt;

  final String? tokenId;

  const DigitalTwinMetadata({
    required this.id,
    required this.collectionId,
    required this.collection,
    required this.creatorId,
    required this.twinTokenMetadataCID,
    required this.imageCID,
    required this.imageLink,
    required this.traits,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.tokenId,
  });
}

enum DigitalTwinCreationMetadataStatus {
  @JsonValue("PENDING")
  pending,
  @JsonValue("DRAFT")
  draft,
  @JsonValue("MINTED")
  minted,
  @JsonValue("TO_BE_BURNED")
  toBeBurned,
  @JsonValue("TO_BE_TRANSFERRED")
  toBeTransferred,
  @JsonValue("BURNED")
  burned,
  @JsonValue("UNKNOWN")
  unknown,
}

const DigitalTwinCreationMetadataStatusEnumMap = {
  DigitalTwinCreationMetadataStatus.pending: 'PENDING',
  DigitalTwinCreationMetadataStatus.toBeBurned: 'TO_BE_BURNED',
  DigitalTwinCreationMetadataStatus.draft: 'DRAFT',
  DigitalTwinCreationMetadataStatus.toBeTransferred: 'TO_BE_TRANSFERRED',
  DigitalTwinCreationMetadataStatus.minted: 'MINTED',
  DigitalTwinCreationMetadataStatus.burned: 'BURNED',
};
