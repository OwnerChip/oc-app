// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'web3AuthProvidersDto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Web3AuthProvidersDto _$Web3AuthProvidersDtoFromJson(
        Map<String, dynamic> json) =>
    Web3AuthProvidersDto(
      providers: (json['providers'] as List<dynamic>)
          .map((e) => Web3AuthDataDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      email: json['email'] as String,
    );

Map<String, dynamic> _$Web3AuthProvidersDtoToJson(
        Web3AuthProvidersDto instance) =>
    <String, dynamic>{
      'providers': instance.providers.map((e) => e.toJson()).toList(),
      'email': instance.email,
    };
