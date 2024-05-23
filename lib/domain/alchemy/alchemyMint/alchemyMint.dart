import 'package:json_annotation/json_annotation.dart';
import 'package:ownerchip_whitelabel/domain/converters/dateIso8601NullSafetyJsonConverter.dart';

part 'alchemyMint.g.dart';

@JsonSerializable(explicitToJson: true)
class Mint {
  factory Mint.fromJson(Map<String, dynamic> json) => _$MintFromJson(json);

  Map<String, dynamic> toJson() => _$MintToJson(this);

  String? mintAddress;
  int? blockNumber;

  @DateIso8601NullSafetyJsonConverter()
  DateTime? timestamp;
  String? transactionHash;

  Mint({
    required this.mintAddress,
    required this.blockNumber,
    required this.timestamp,
    required this.transactionHash,
  });
}
