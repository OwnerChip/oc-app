import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/domain/creation/digitalTwinAttachment.dart';
import 'package:ownerchip_whitelabel/domain/creation/digitalTwinMetadata.dart';
import 'package:ownerchip_whitelabel/services/backend/creation/backendCreation.dart';
import 'package:ownerchip_whitelabel/services/providers/chipData.dart';

/// get creation data for by token id
final creationData =
    FutureProvider.autoDispose<DigitalTwinMetadata?>((ref) async {
  final chipInfo = ref.watch(chipInfoProvider);

  if (!chipInfo.chipIsInitialized) {
    return null;
  }

  final data = await BackendCreation.getDigitalTwinByTokenId(
      tokenId: '0x${chipInfo.tokenId.toRadixString(16)}');

  return data;
});

/// get attachments for the creation by token id
final digitalTwinAttachmentsProvider =
    FutureProvider.autoDispose<List<DigitalTwinAttachment>?>((ref) async {
  final creation = ref.watch(creationData);

  if (creation.isLoading) {
    return [];
  }

  if (creation.asData?.value == null) {
    return [];
  }

  final data = await BackendCreation.getDigitalTwinAttachments(
    id: creation.asData!.value!.id,
  );

  return data;
});
