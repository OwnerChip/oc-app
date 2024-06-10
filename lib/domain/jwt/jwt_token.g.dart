// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jwt_token.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JwtToken _$JwtTokenFromJson(Map<String, dynamic> json) => JwtToken(
      raw: json['raw'] as String,
      walletAddress: json['walletAddress'] as String?,
      sessionId: json['sessionId'] as String,
      role: json['role'] as String,
      iatS: (json['iat'] as num).toInt(),
      expS: (json['exp'] as num).toInt(),
    );

Map<String, dynamic> _$JwtTokenToJson(JwtToken instance) => <String, dynamic>{
      'raw': instance.raw,
      'walletAddress': instance.walletAddress,
      'sessionId': instance.sessionId,
      'role': instance.role,
      'iat': instance.iatS,
      'exp': instance.expS,
    };
