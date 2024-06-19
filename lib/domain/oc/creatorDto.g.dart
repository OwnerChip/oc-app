// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'creatorDto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreatorDto _$CreatorDtoFromJson(Map<String, dynamic> json) => CreatorDto(
      address: json['address'] as String,
      name: json['name'] as String,
      affiliation: json['affiliation'] as String,
      email: json['email'] as String,
      isOwnercard: json['is_ownercard'] as bool,
    );

Map<String, dynamic> _$CreatorDtoToJson(CreatorDto instance) =>
    <String, dynamic>{
      'address': instance.address,
      'name': instance.name,
      'affiliation': instance.affiliation,
      'email': instance.email,
      'is_ownercard': instance.isOwnercard,
    };
