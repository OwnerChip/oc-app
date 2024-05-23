import 'package:json_annotation/json_annotation.dart';
import 'package:ownerchip_whitelabel/domain/converters/ethereumAddressJsonConverter.dart';
import 'package:web3dart/web3dart.dart';

part 'rariblePayout.g.dart';

@JsonSerializable(explicitToJson: true)
class RariblePayout {
  factory RariblePayout.fromJson(Map<String, dynamic> json) =>
      _$RariblePayoutFromJson(json);

  Map<String, dynamic> toJson() => _$RariblePayoutToJson(this);

  @EthereumAddressJsonConverter()
  final EthereumAddress account;
  final int value; // in bps (100=1%)

  RariblePayout({
    required this.account,
    required this.value,
  });
}
