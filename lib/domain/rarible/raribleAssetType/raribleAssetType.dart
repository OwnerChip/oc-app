import 'package:json_annotation/json_annotation.dart';
import 'package:ownerchip_whitelabel/domain/converters/ethereumAddressNullsafetyJsonConverter.dart';
import 'package:web3dart/web3dart.dart';

part 'raribleAssetType.g.dart';

@JsonSerializable(explicitToJson: true)
class RaribleAssetType {
  factory RaribleAssetType.fromJson(Map<String, dynamic> json) =>
      _$RaribleAssetTypeFromJson(json);

  Map<String, dynamic> toJson() => _$RaribleAssetTypeToJson(this);

  final String assetClass;

  @EthereumAddressNullsafetyJsonConverter()
  final EthereumAddress? contract;
  final BigInt? tokenId;

  RaribleAssetType({required this.assetClass, this.contract, this.tokenId});
}
