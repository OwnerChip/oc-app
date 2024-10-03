// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'digitalTwinTrait.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DigitalTwinTrait _$DigitalTwinTraitFromJson(Map<String, dynamic> json) =>
    DigitalTwinTrait(
      traitType: json['trait_type'] as String,
      value: json['value'] as String,
    );

Map<String, dynamic> _$DigitalTwinTraitToJson(DigitalTwinTrait instance) =>
    <String, dynamic>{
      'trait_type': instance.traitType,
      'value': instance.value,
    };
