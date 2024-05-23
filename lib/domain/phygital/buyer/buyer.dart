import 'package:json_annotation/json_annotation.dart';
import 'package:ownerchip_whitelabel/domain/converters/dateIso8601NullSafetyJsonConverter.dart';
import 'package:ownerchip_whitelabel/domain/converters/ethereumAddressNullsafetyJsonConverter.dart';
import 'package:web3dart/web3dart.dart';

part 'buyer.g.dart';

@JsonSerializable(explicitToJson: true)
class Buyer {
  factory Buyer.fromJson(Map<String, dynamic> json) => _$BuyerFromJson(json);

  Map<String, dynamic> toJson() => _$BuyerToJson(this);

  @EthereumAddressNullsafetyJsonConverter()
  EthereumAddress? walletAddress;
  String? firstName;
  String? lastName;
  String? email;
  String? phoneNumber;

  @DateIso8601NullSafetyJsonConverter()
  DateTime? createdAt;
  String? companyName;

  Buyer({
    required this.walletAddress,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.createdAt,
    required this.companyName,
  });
}
