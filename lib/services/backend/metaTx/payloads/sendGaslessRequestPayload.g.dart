// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sendGaslessRequestPayload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SendGaslessRequestPayload _$SendGaslessRequestPayloadFromJson(
        Map<String, dynamic> json) =>
    SendGaslessRequestPayload(
      txSignature: json['txSignature'] as String,
      metaTxAgreementId: json['metaTxAgreementId'] as String,
      txRequest: json['txRequest'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$SendGaslessRequestPayloadToJson(
        SendGaslessRequestPayload instance) =>
    <String, dynamic>{
      'txSignature': instance.txSignature,
      'metaTxAgreementId': instance.metaTxAgreementId,
      'txRequest': instance.txRequest,
    };
