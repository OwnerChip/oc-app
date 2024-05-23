import 'package:json_annotation/json_annotation.dart';
import 'package:ownerchip_whitelabel/domain/openSea/openSeaMetadata/openSeaMetadata.dart';

part 'alchemyContract.g.dart';

@JsonSerializable(explicitToJson: true)
class AlchemyContract {
  factory AlchemyContract.fromJson(Map<String, dynamic> json) =>
      _$AlchemyContractFromJson(json);

  Map<String, dynamic> toJson() => _$AlchemyContractToJson(this);

  String address;
  String name;
  String symbol;
  dynamic totalSupply;
  String tokenType;
  String contractDeployer;
  int deployedBlockNumber;
  OpenSeaMetadata openSeaMetadata;
  dynamic isSpam;
  List<dynamic> spamClassifications;

  AlchemyContract({
    required this.address,
    required this.name,
    required this.symbol,
    this.totalSupply,
    required this.tokenType,
    required this.contractDeployer,
    required this.deployedBlockNumber,
    required this.openSeaMetadata,
    this.isSpam,
    required this.spamClassifications,
  });
}
