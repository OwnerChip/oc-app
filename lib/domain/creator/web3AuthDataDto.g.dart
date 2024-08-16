// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'web3AuthDataDto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Web3AuthDataDto _$Web3AuthDataDtoFromJson(Map<String, dynamic> json) =>
    Web3AuthDataDto(
      address: json['address'] as String,
      name: json['name'] as String?,
      email: json['email'] as String?,
      picture: json['picture'] as String?,
      providerType: json['providerType'] as String,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );

Map<String, dynamic> _$Web3AuthDataDtoToJson(Web3AuthDataDto instance) =>
    <String, dynamic>{
      'address': instance.address,
      'name': instance.name,
      'email': instance.email,
      'picture': instance.picture,
      'providerType': instance.providerType,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };
