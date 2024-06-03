// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'getSessionExpirationPayload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetSessionExpirationPayload _$GetSessionExpirationPayloadFromJson(
        Map<String, dynamic> json) =>
    GetSessionExpirationPayload(
      sessionId: json['sessionId'] as String,
      walletAddress: json['walletAddress'] as String,
      userWalletSignature: WalletSignature.fromJson(
          json['userWalletSignature'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GetSessionExpirationPayloadToJson(
        GetSessionExpirationPayload instance) =>
    <String, dynamic>{
      'sessionId': instance.sessionId,
      'walletAddress': instance.walletAddress,
      'userWalletSignature': instance.userWalletSignature.toJson(),
    };
