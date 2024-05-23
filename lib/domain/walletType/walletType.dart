import 'package:json_annotation/json_annotation.dart';

part 'walletType.g.dart';

@JsonSerializable(explicitToJson: true)
class WalletType {
  factory WalletType.fromJson(Map<String, dynamic> json) =>
      _$WalletTypeFromJson(json);

  Map<String, dynamic> toJson() => _$WalletTypeToJson(this);

  final String name;
  final String iconUri;

  WalletType(this.name, this.iconUri);
}

