// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'getMeResponse.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetMeResponse _$GetMeResponseFromJson(Map<String, dynamic> json) =>
    GetMeResponse(
      userWalletAddress: json['userWalletAddress'] as String,
      role: json['role'] as String,
    );

Map<String, dynamic> _$GetMeResponseToJson(GetMeResponse instance) =>
    <String, dynamic>{
      'userWalletAddress': instance.userWalletAddress,
      'role': instance.role,
    };
