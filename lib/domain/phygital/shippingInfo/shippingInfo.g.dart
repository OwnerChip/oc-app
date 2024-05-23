// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shippingInfo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShippingInfo _$ShippingInfoFromJson(Map<String, dynamic> json) => ShippingInfo(
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String,
      companyName: json['companyName'] as String,
      streetAddress: json['streetAddress'] as String,
      streetAddress1: json['streetAddress1'] as String,
      city: json['city'] as String,
      postalCode: json['postalCode'] as String,
      stateOrProvince: json['stateOrProvince'] as String,
      countryCode: json['countryCode'] as String,
    );

Map<String, dynamic> _$ShippingInfoToJson(ShippingInfo instance) =>
    <String, dynamic>{
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'email': instance.email,
      'phoneNumber': instance.phoneNumber,
      'companyName': instance.companyName,
      'streetAddress': instance.streetAddress,
      'streetAddress1': instance.streetAddress1,
      'city': instance.city,
      'postalCode': instance.postalCode,
      'stateOrProvince': instance.stateOrProvince,
      'countryCode': instance.countryCode,
    };
