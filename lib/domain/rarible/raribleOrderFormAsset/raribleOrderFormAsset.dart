import 'package:json_annotation/json_annotation.dart';
import 'package:ownerchip_whitelabel/domain/rarible/raribleAssetType/raribleAssetType.dart';

part 'raribleOrderFormAsset.g.dart';

@JsonSerializable(explicitToJson: true)
class RaribleOrderFormAsset {
  factory RaribleOrderFormAsset.fromJson(Map<String, dynamic> json) =>
      _$RaribleOrderFormAssetFromJson(json);

  Map<String, dynamic> toJson() => _$RaribleOrderFormAssetToJson(this);
  final RaribleAssetType assetType;
  final BigInt value;

  RaribleOrderFormAsset({required this.assetType, required this.value});
}
