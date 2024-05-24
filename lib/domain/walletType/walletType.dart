import 'package:json_annotation/json_annotation.dart';
import 'package:ownerchip_whitelabel/domain/converters/eWalletTypeJsonConverter.dart';
import 'package:ownerchip_whitelabel/domain/walletType/eWalletType.dart';

part 'walletType.g.dart';


@JsonSerializable(explicitToJson: true)
class WalletType {
  factory WalletType.fromJson(Map<String, dynamic> json) =>
      _$WalletTypeFromJson(json);

  Map<String, dynamic> toJson() => _$WalletTypeToJson(this);

  final String name;
  final String iconUri;

  @EWalletTypeJsonConverter()
  final EWalletType type;

  WalletType(
      this.name,
      this.iconUri,
      this.type,
      );

}

