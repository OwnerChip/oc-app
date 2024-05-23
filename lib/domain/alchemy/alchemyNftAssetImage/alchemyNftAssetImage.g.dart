// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alchemyNftAssetImage.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AlchemyNftAssetImage _$AlchemyNftAssetImageFromJson(
        Map<String, dynamic> json) =>
    AlchemyNftAssetImage(
      cachedUrl: json['cachedUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      pngUrl: json['pngUrl'] as String,
      contentType: json['contentType'] as String?,
      size: json['size'],
      originalUrl: json['originalUrl'] as String?,
    );

Map<String, dynamic> _$AlchemyNftAssetImageToJson(
        AlchemyNftAssetImage instance) =>
    <String, dynamic>{
      'cachedUrl': instance.cachedUrl,
      'thumbnailUrl': instance.thumbnailUrl,
      'pngUrl': instance.pngUrl,
      'contentType': instance.contentType,
      'size': instance.size,
      'originalUrl': instance.originalUrl,
    };
