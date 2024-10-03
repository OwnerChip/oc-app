// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'getMeResponse.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetMeResponse _$GetMeResponseFromJson(Map<String, dynamic> json) =>
    GetMeResponse(
      walletAddress: json['walletAddress'] as String,
      role: json['role'] as String,
    );

Map<String, dynamic> _$GetMeResponseToJson(GetMeResponse instance) =>
    <String, dynamic>{
      'walletAddress': instance.walletAddress,
      'role': instance.role,
    };
