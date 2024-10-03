import 'package:json_annotation/json_annotation.dart';
import 'package:ownerchip_whitelabel/domain/converters/dateTimeJsonConverter.dart';

part 'ocCollection.g.dart';

@JsonSerializable(explicitToJson: true)
class OCCollection {
  factory OCCollection.fromJson(Map<String, dynamic> json) =>
      _$OCCollectionFromJson(json);

  Map<String, dynamic> toJson() => _$OCCollectionToJson(this);
  final String address;
  final String voucherAddress;
  final String name;
  final String symbol;
  final int chainId;


  const OCCollection({
    required this.address,
    required this.voucherAddress,
    required this.name,
    required this.symbol,
    required this.chainId,
  });
}
