// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'raribleDataObject.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RaribleDataObject _$RaribleDataObjectFromJson(Map<String, dynamic> json) =>
    RaribleDataObject(
      dataType: json['dataType'] as String,
      payouts: (json['payouts'] as List<dynamic>)
          .map((e) => RariblePayout.fromJson(e as Map<String, dynamic>))
          .toList(),
      originFees: (json['originFees'] as List<dynamic>)
          .map((e) => RariblePayout.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$RaribleDataObjectToJson(RaribleDataObject instance) =>
    <String, dynamic>{
      'dataType': instance.dataType,
      'payouts': instance.payouts.map((e) => e.toJson()).toList(),
      'originFees': instance.originFees.map((e) => e.toJson()).toList(),
    };
