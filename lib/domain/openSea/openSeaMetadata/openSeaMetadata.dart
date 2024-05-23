import 'package:json_annotation/json_annotation.dart';
import 'package:ownerchip_whitelabel/domain/converters/dateIso8601NullSafetyJsonConverter.dart';

part 'openSeaMetadata.g.dart';

@JsonSerializable(explicitToJson: true)
class OpenSeaMetadata {
  factory OpenSeaMetadata.fromJson(Map<String, dynamic> json) =>
      _$OpenSeaMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$OpenSeaMetadataToJson(this);

  dynamic floorPrice;
  dynamic collectionName;
  dynamic collectionSlug;
  dynamic safelistRequestStatus;
  dynamic imageUrl;
  dynamic description;
  dynamic externalUrl;
  dynamic twitterUsername;
  dynamic discordUrl;
  dynamic bannerImageUrl;

  @DateIso8601NullSafetyJsonConverter()
  DateTime? lastIngestedAt;

  OpenSeaMetadata({
    this.floorPrice,
    this.collectionName,
    this.collectionSlug,
    this.safelistRequestStatus,
    this.imageUrl,
    this.description,
    this.externalUrl,
    this.twitterUsername,
    this.discordUrl,
    this.bannerImageUrl,
    this.lastIngestedAt,
  });

// temp
}
