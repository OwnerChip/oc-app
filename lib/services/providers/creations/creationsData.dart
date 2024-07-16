import 'package:ownerchip_whitelabel/domain/common/backendPaginationResponse.dart';
import 'package:ownerchip_whitelabel/domain/creation/digitalTwinMetadata.dart';

class CreationsData {
  final BackendPaginationResponse<DigitalTwinMetadata>? data;
  final bool loading;
  final bool initialized;
  final bool error;

  const CreationsData(
      {required this.data,
      required this.loading,
      required this.initialized,
      required this.error});

  factory CreationsData.initial() {
    return const CreationsData(
      data: null,
      loading: false,
      initialized: false,
      error: false,
    );
  }

  CreationsData copyWith({
    BackendPaginationResponse<DigitalTwinMetadata>? data,
    bool? loading,
    bool? initialized,
    bool? error,
  }) {
    return CreationsData(
      data: data ?? this.data,
      loading: loading ?? this.loading,
      initialized: initialized ?? this.initialized,
      error: error ?? this.error,
    );
  }
}
