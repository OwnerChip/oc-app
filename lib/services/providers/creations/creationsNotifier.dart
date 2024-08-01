import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/domain/creation/digitalTwinMetadata.dart';
import 'package:ownerchip_whitelabel/services/backend/creation/backendCreation.dart';
import 'package:ownerchip_whitelabel/services/providers/creations/creationsData.dart';

class CreationsNotifier extends Notifier<CreationsData> {
  @override
  CreationsData build() {
    return CreationsData.initial();
  }

  Future<void> onLogout() async {
    state = CreationsData.initial();
  }

  Future<void> init() async {
    state = state.copyWith(loading: true);

    try {
      // Fetch data from backend
      final data = await BackendCreation.getMyDigitalTwins(
        1,
        status: [
          DigitalTwinCreationMetadataStatus.pending,
          DigitalTwinCreationMetadataStatus.toBeBurned,
          DigitalTwinCreationMetadataStatus.toBeTransferred,
        ],
      );

      state = state.copyWith(
        data: data,
        loading: false,
        initialized: true,
      );
    } catch (e) {
      state = state.copyWith(error: true, loading: false);
    }
  }
}

final creationsNotifierProvider =
    NotifierProvider<CreationsNotifier, CreationsData>(
  CreationsNotifier.new,
);
