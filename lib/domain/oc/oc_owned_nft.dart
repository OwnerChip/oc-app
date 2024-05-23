import 'package:json_annotation/json_annotation.dart';
import 'package:ownerchip_whitelabel/domain/alchemy/alchemyContract/alchemyContract.dart';
import 'package:ownerchip_whitelabel/domain/oc/oc_nft_image.dart';

part 'oc_owned_nft.g.dart';

@JsonSerializable(explicitToJson: true)
class OcOwnedNft {
  factory OcOwnedNft.fromJson(Map<String, dynamic> json) =>
      _$OcOwnedNftFromJson(json);

  Map<String, dynamic> toJson() => _$OcOwnedNftToJson(this);

  final AlchemyContract contract;

  final String tokenId;

  final String tokenType;
  final String name;
  final String? description;
  final String tokenUri;
  final OcNftImage image;

  const OcOwnedNft({
    required this.contract,
    required this.tokenId,
    required this.tokenType,
    required this.name,
    required this.description,
    required this.tokenUri,
    required this.image,
  });
}
