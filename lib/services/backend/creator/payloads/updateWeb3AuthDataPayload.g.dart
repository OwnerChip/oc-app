// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'updateWeb3AuthDataPayload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateWeb3AuthDataPayload _$UpdateWeb3AuthDataPayloadFromJson(
        Map<String, dynamic> json) =>
    UpdateWeb3AuthDataPayload(
      name: json['name'] as String?,
      email: json['email'] as String?,
      picture: json['picture'] as String?,
      providerType: json['providerType'] as String,
    );

Map<String, dynamic> _$UpdateWeb3AuthDataPayloadToJson(
        UpdateWeb3AuthDataPayload instance) =>
    <String, dynamic>{
      'name': instance.name,
      'email': instance.email,
      'picture': instance.picture,
      'providerType': instance.providerType,
    };
