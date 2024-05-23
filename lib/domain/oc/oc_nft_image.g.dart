// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'oc_nft_image.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OcNftImage _$OcNftImageFromJson(Map<String, dynamic> json) => OcNftImage(
      cachedUrl: json['cachedUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      pngUrl: json['pngUrl'] as String?,
      contentType: json['contentType'] as String?,
      size: (json['size'] as num?)?.toInt(),
      originalUrl: json['originalUrl'] as String,
    );

Map<String, dynamic> _$OcNftImageToJson(OcNftImage instance) =>
    <String, dynamic>{
      'cachedUrl': instance.cachedUrl,
      'thumbnailUrl': instance.thumbnailUrl,
      'pngUrl': instance.pngUrl,
      'contentType': instance.contentType,
      'size': instance.size,
      'originalUrl': instance.originalUrl,
    };
