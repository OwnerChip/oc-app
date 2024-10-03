// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cardInitPayload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CardInitPayload _$CardInitPayloadFromJson(Map<String, dynamic> json) =>
    CardInitPayload(
      id: json['id'] as String,
      isCertificateCard: json['isCertificateCard'] as bool? ?? false,
    );

Map<String, dynamic> _$CardInitPayloadToJson(CardInitPayload instance) =>
    <String, dynamic>{
      'id': instance.id,
      'isCertificateCard': instance.isCertificateCard,
    };
