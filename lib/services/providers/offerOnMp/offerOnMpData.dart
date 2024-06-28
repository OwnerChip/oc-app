

import 'package:ownerchip_whitelabel/domain/oc/creatorDto.dart';

class OfferOnMpData {

  final CreatorDto? creatorDto;
  final bool loading;
  final bool error;

  const OfferOnMpData({
    this.creatorDto,
    required this.loading,
    required this.error,
  });

  factory OfferOnMpData.initial() {
    return const OfferOnMpData(
      creatorDto: null,
      loading: false,
      error: false,
    );
  }

  OfferOnMpData copyWith({
    CreatorDto? creatorDto,
    bool? loading,
    bool? error,
  }) {
    return OfferOnMpData(
      creatorDto: creatorDto ?? this.creatorDto,
      loading: loading ?? this.loading,
      error: error ?? this.error,
    );
  }
}