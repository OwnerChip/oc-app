import 'package:json_annotation/json_annotation.dart';
import 'package:ownerchip_whitelabel/domain/app/appDto.dart';

class AppData {
  final AppDto? appDto;
  final bool isLoading;
  final bool hasError;
  final bool upgradeShown;
  final bool upgradeRequired;

  factory AppData.initial() {
    return const AppData(
      appDto: null,
      isLoading: false,
      hasError: false,
      upgradeShown: false,
      upgradeRequired: false,
    );
  }

  const AppData({
    this.appDto,
    required this.isLoading,
    required this.hasError,
    required this.upgradeShown,
    this.upgradeRequired = false,
  });

  AppData copyWith({
    AppDto? appDto,
    bool? isLoading,
    bool? hasError,
    bool? upgradeShown,
    bool? upgradeRequired,
  }) {
    return AppData(
      appDto: appDto ?? this.appDto,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      upgradeShown: upgradeShown ?? this.upgradeShown,
      upgradeRequired: upgradeRequired ?? this.upgradeRequired,
    );
  }
}
