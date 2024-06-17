// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'userSession.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserSession _$UserSessionFromJson(Map<String, dynamic> json) => UserSession(
      json['sessionId'] as String,
      const MsgSignatureJsonConverter().fromJson(json['signatureData'] as Map),
      const EthereumAddressJsonConverter()
          .fromJson(json['userWalletAddress'] as String),
      json['isOwnerCard'] as bool,
      JwtToken.fromJson(json['jwt'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserSessionToJson(UserSession instance) =>
    <String, dynamic>{
      'sessionId': instance.sessionId,
      'signatureData':
          const MsgSignatureJsonConverter().toJson(instance.signatureData),
      'userWalletAddress': const EthereumAddressJsonConverter()
          .toJson(instance.userWalletAddress),
      'isOwnerCard': instance.isOwnerCard,
      'jwt': instance.jwt.toJson(),
    };
