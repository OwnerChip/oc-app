import 'package:json_annotation/json_annotation.dart';
import 'package:ownerchip_whitelabel/domain/alchemy/alchemyAcquiredAt/alchemyAcquiredAt.dart';
import 'package:ownerchip_whitelabel/domain/alchemy/alchemyContract/alchemyContract.dart';
import 'package:ownerchip_whitelabel/domain/alchemy/alchemyMint/alchemyMint.dart';
import 'package:ownerchip_whitelabel/domain/alchemy/alchemyNftAssetImage/alchemyNftAssetImage.dart';
import 'package:ownerchip_whitelabel/domain/alchemy/alchemyRaw/alchemyRaw.dart';
import 'package:ownerchip_whitelabel/domain/converters/dateIso8601JsonConverter.dart';

part 'alchemyNftAsset.g.dart';

@JsonSerializable(explicitToJson: true)
class AlchemyNFTAsset {

	factory AlchemyNFTAsset.fromJson(Map<String, dynamic> json) => _$AlchemyNFTAssetFromJson(json);
	Map<String, dynamic> toJson( ) => _$AlchemyNFTAssetToJson(this);

  AlchemyContract contract;
  String tokenId;
  String tokenType;
  String name;
  String? description;
  String tokenUri;
  AlchemyNftAssetImage image;
  AlchemyRaw raw;
  dynamic collection; // Since the type is not specified
  Mint mint;
  dynamic owners; // Since the type is not specified

  @DateIso8601JsonConverter()
  DateTime timeLastUpdated;
  int balance;
  AcquiredAt acquiredAt;

  AlchemyNFTAsset({
    required this.contract,
    required this.tokenId,
    required this.tokenType,
    required this.name,
    this.description,
    required this.tokenUri,
    required this.image,
    required this.raw,
    this.collection,
    required this.mint,
    this.owners,
    required this.timeLastUpdated,
    required this.balance,
    required this.acquiredAt,
  });


}
