import 'package:json_annotation/json_annotation.dart';
import 'package:ownerchip_whitelabel/domain/creator/web3AuthDataDto.dart';

part 'web3AuthProvidersDto.g.dart';

@JsonSerializable(explicitToJson: true)
class Web3AuthProvidersDto {
  factory Web3AuthProvidersDto.fromJson(Map<String, dynamic> json) =>
      _$Web3AuthProvidersDtoFromJson(json);

  Map<String, dynamic> toJson() => _$Web3AuthProvidersDtoToJson(this);

  final List<Web3AuthDataDto> providers;

  final String email;

  const Web3AuthProvidersDto({
    required this.providers,
    required this.email,
  });
}

