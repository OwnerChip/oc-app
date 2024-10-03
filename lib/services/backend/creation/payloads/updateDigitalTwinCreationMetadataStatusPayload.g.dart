// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'updateDigitalTwinCreationMetadataStatusPayload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateDigitalTwinCreationMetadataStatusPayload
    _$UpdateDigitalTwinCreationMetadataStatusPayloadFromJson(
            Map<String, dynamic> json) =>
        UpdateDigitalTwinCreationMetadataStatusPayload(
          status: $enumDecode(
              _$DigitalTwinCreationMetadataStatusEnumMap, json['status']),
        );

Map<String, dynamic> _$UpdateDigitalTwinCreationMetadataStatusPayloadToJson(
        UpdateDigitalTwinCreationMetadataStatusPayload instance) =>
    <String, dynamic>{
      'status': _$DigitalTwinCreationMetadataStatusEnumMap[instance.status]!,
    };

const _$DigitalTwinCreationMetadataStatusEnumMap = {
  DigitalTwinCreationMetadataStatus.pending: 'PENDING',
  DigitalTwinCreationMetadataStatus.draft: 'DRAFT',
  DigitalTwinCreationMetadataStatus.minted: 'MINTED',
  DigitalTwinCreationMetadataStatus.toBeBurned: 'TO_BE_BURNED',
  DigitalTwinCreationMetadataStatus.toBeTransferred: 'TO_BE_TRANSFERRED',
  DigitalTwinCreationMetadataStatus.burned: 'BURNED',
  DigitalTwinCreationMetadataStatus.unknown: 'UNKNOWN',
};
