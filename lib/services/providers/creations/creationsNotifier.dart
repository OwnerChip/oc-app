import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/domain/creation/digitalTwinMetadata.dart';
import 'package:ownerchip_whitelabel/services/backend/creation/backendCreation.dart';
import 'package:ownerchip_whitelabel/services/providers/creations/creationsData.dart';

class CreationsNotifier extends Notifier<CreationsData> {
  @override
  CreationsData build() {
    return CreationsData.initial();
  }

  Future<void> init() async {
    state = state.copyWith(loading: true);

    try {
      // Fetch data from backend
      final data = await Future.wait([
        BackendCreation.getMyDigitalTwins(
          1,
          status: [
            DigitalTwinCreationMetadataStatus.pending,
          ],
        ),
        BackendCreation.getMyDigitalTwins(
          1,
          status: [
            DigitalTwinCreationMetadataStatus.toBeBurned,
          ],
        ),
      ]);

      state = state.copyWith(
        toBeMintedData: data[0],
        toBeBurnedData: data[1],
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
