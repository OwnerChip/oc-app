import 'package:json_annotation/json_annotation.dart';
import 'package:ownerchip_whitelabel/domain/rarible/rariblePayout/rariblePayout.dart';

part 'raribleDataObject.g.dart';

@JsonSerializable(explicitToJson: true)
class RaribleDataObject {
  factory RaribleDataObject.fromJson(Map<String, dynamic> json) =>
      _$RaribleDataObjectFromJson(json);

  Map<String, dynamic> toJson() => _$RaribleDataObjectToJson(this);

  final String dataType;
  final List<RariblePayout> payouts;
  final List<RariblePayout> originFees;

  RaribleDataObject(
      {required this.dataType,
      required this.payouts,
      required this.originFees});
}
