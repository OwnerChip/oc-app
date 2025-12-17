import 'package:json_annotation/json_annotation.dart';
import 'package:ownerchip_whitelabel/domain/converters/dateTimeJsonConverter.dart';

part 'digitalTwinSeriesItem.g.dart';

@JsonSerializable(explicitToJson: true)
class DigitalTwinSeriesItem {
  factory DigitalTwinSeriesItem.fromJson(Map<String, dynamic> json) =>
      _$DigitalTwinSeriesItemFromJson(json);

  Map<String, dynamic> toJson() => _$DigitalTwinSeriesItemToJson(this);

  DigitalTwinSeriesItem({
    required this.uid,
    required this.ownerId,
    this.imageCID,
    this.imageLink,
    this.twinTokenMetadataCID,
    this.voucherTokenMetadataCID,
    required this.createdAt,
    this.mintingDate,
    this.tokenId,
    required this.digitalTwinTokenMetadataUID,
  });

  final String uid;
  final String ownerId;
  final String? imageCID;
  final String? imageLink;
  final String? twinTokenMetadataCID;
  final String? voucherTokenMetadataCID;

  @DateTimeJsonConverter()
  final DateTime createdAt;

  final DateTime? mintingDate;
  final String? tokenId;
  final String digitalTwinTokenMetadataUID;
}
