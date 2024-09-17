import 'package:json_annotation/json_annotation.dart';

import 'package:ownerchip_whitelabel/domain/appVersion/appVersion.dart';

part 'appDto.g.dart';

@JsonSerializable(explicitToJson: true)
class AppDto {
  factory AppDto.fromJson(Map<String, dynamic> json) => _$AppDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AppDtoToJson(this);

  final String appStoreLink;

  final String googlePlayLink;

  final AppVersion? minRequiredVersion;

  const AppDto({
    required this.appStoreLink,
    required this.googlePlayLink,
    required this.minRequiredVersion,
  });
}
