// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alchemyRaw.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AlchemyRaw _$AlchemyRawFromJson(Map<String, dynamic> json) => AlchemyRaw(
      tokenUri: json['tokenUri'] as String,
      metadata: Metadata.fromJson(json['metadata'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$AlchemyRawToJson(AlchemyRaw instance) =>
    <String, dynamic>{
      'tokenUri': instance.tokenUri,
      'metadata': instance.metadata.toJson(),
      'error': instance.error,
    };
