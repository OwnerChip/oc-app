import 'package:json_annotation/json_annotation.dart';

part 'web3AuthDataDto.g.dart';

@JsonSerializable(explicitToJson: true)
class Web3AuthDataDto {

  factory Web3AuthDataDto.fromJson(Map<String, dynamic> json) =>
      _$Web3AuthDataDtoFromJson(json);

  Map<String, dynamic> toJson() => _$Web3AuthDataDtoToJson(this);

  final String address;

  final String? name;

  final String? email;

  final String? picture;

  final String providerType;

  final String createdAt;

  final String updatedAt;

  const Web3AuthDataDto({
    required this.address,
    this.name,
    this.email,
    this.picture,
    required this.providerType,
    required this.createdAt,
    required this.updatedAt,
  });

}