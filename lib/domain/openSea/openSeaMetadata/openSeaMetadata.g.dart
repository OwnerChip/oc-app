// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'openSeaMetadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OpenSeaMetadata _$OpenSeaMetadataFromJson(Map<String, dynamic> json) =>
    OpenSeaMetadata(
      floorPrice: json['floorPrice'],
      collectionName: json['collectionName'],
      collectionSlug: json['collectionSlug'],
      safelistRequestStatus: json['safelistRequestStatus'],
      imageUrl: json['imageUrl'],
      description: json['description'],
      externalUrl: json['externalUrl'],
      twitterUsername: json['twitterUsername'],
      discordUrl: json['discordUrl'],
      bannerImageUrl: json['bannerImageUrl'],
      lastIngestedAt: const DateIso8601NullSafetyJsonConverter()
          .fromJson(json['lastIngestedAt'] as String?),
    );

Map<String, dynamic> _$OpenSeaMetadataToJson(OpenSeaMetadata instance) =>
    <String, dynamic>{
      'floorPrice': instance.floorPrice,
      'collectionName': instance.collectionName,
      'collectionSlug': instance.collectionSlug,
      'safelistRequestStatus': instance.safelistRequestStatus,
      'imageUrl': instance.imageUrl,
      'description': instance.description,
      'externalUrl': instance.externalUrl,
      'twitterUsername': instance.twitterUsername,
      'discordUrl': instance.discordUrl,
      'bannerImageUrl': instance.bannerImageUrl,
      'lastIngestedAt': const DateIso8601NullSafetyJsonConverter()
          .toJson(instance.lastIngestedAt),
    };
