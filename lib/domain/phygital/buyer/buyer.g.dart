// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'buyer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Buyer _$BuyerFromJson(Map<String, dynamic> json) => Buyer(
      walletAddress: const EthereumAddressNullsafetyJsonConverter()
          .fromJson(json['walletAddress'] as String?),
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      createdAt: const DateIso8601NullSafetyJsonConverter()
          .fromJson(json['createdAt'] as String?),
      companyName: json['companyName'] as String?,
    );

Map<String, dynamic> _$BuyerToJson(Buyer instance) => <String, dynamic>{
      'walletAddress': const EthereumAddressNullsafetyJsonConverter()
          .toJson(instance.walletAddress),
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'email': instance.email,
      'phoneNumber': instance.phoneNumber,
      'createdAt':
          const DateIso8601NullSafetyJsonConverter().toJson(instance.createdAt),
      'companyName': instance.companyName,
    };
