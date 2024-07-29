import 'package:ownerchip_whitelabel/domain/common/backendPaginationResponse.dart';
import 'package:ownerchip_whitelabel/domain/creation/digitalTwinMetadata.dart';

class CreationsData {
  final BackendPaginationResponse<DigitalTwinMetadata>? toBeMintedData;
  final BackendPaginationResponse<DigitalTwinMetadata>? toBeBurnedData;
  final bool loading;
  final bool initialized;
  final bool error;

  const CreationsData(
      {required this.toBeMintedData,
      required this.toBeBurnedData,
      required this.loading,
      required this.initialized,
      required this.error});

  factory CreationsData.initial() {
    return const CreationsData(
      toBeMintedData: null,
      toBeBurnedData: null,
      loading: false,
      initialized: false,
      error: false,
    );
  }

  CreationsData copyWith({
    BackendPaginationResponse<DigitalTwinMetadata>? toBeMintedData,
    BackendPaginationResponse<DigitalTwinMetadata>? toBeBurnedData,
    bool? loading,
    bool? initialized,
    bool? error,
  }) {
    return CreationsData(
      toBeMintedData: toBeMintedData ?? this.toBeMintedData,
      toBeBurnedData: toBeBurnedData ?? this.toBeBurnedData,
      loading: loading ?? this.loading,
      initialized: initialized ?? this.initialized,
      error: error ?? this.error,
    );
  }
}
