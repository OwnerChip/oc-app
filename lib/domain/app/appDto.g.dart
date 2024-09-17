// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appDto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppDto _$AppDtoFromJson(Map<String, dynamic> json) => AppDto(
      appStoreLink: json['appStoreLink'] as String,
      googlePlayLink: json['googlePlayLink'] as String,
      minRequiredVersion: json['minRequiredVersion'] == null
          ? null
          : AppVersion.fromJson(
              json['minRequiredVersion'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AppDtoToJson(AppDto instance) => <String, dynamic>{
      'appStoreLink': instance.appStoreLink,
      'googlePlayLink': instance.googlePlayLink,
      'minRequiredVersion': instance.minRequiredVersion?.toJson(),
    };
