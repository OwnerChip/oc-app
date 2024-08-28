import 'package:ownerchip_whitelabel/domain/common/backendPaginationResponse.dart';
import 'package:ownerchip_whitelabel/domain/creation/digitalTwinMetadata.dart';

class CreationsData {
  final List<DigitalTwinMetadata>? data;
  final int page;
  final int totalPages;
  final int total;
  final bool loading;
  final bool initialized;
  final bool error;

  factory CreationsData.initial() {
    return const CreationsData(
      data: null,
      loading: false,
      initialized: false,
      error: false,
      page: 1,
      totalPages: 1,
      total: 0,
    );
  }

  const CreationsData({
    this.data,
    required this.page,
    required this.totalPages,
    this.total = 0,
    required this.loading,
    required this.initialized,
    required this.error,
  });

  CreationsData copyWith({
    List<DigitalTwinMetadata>? data,
    int? page,
    int? totalPages,
    int? total,
    bool? loading,
    bool? initialized,
    bool? error,
  }) {
    return CreationsData(
      data: data ?? this.data,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      total: total ?? this.total,
      loading: loading ?? this.loading,
      initialized: initialized ?? this.initialized,
      error: error ?? this.error,
    );
  }
}
