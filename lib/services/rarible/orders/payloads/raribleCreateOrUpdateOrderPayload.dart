import 'package:json_annotation/json_annotation.dart';

part 'raribleCreateOrUpdateOrderPayload.g.dart';

@JsonSerializable(explicitToJson: true)
class RaribleCreateOrUpdateOrderPayload {

	factory RaribleCreateOrUpdateOrderPayload.fromJson(Map<String, dynamic> json) => _$RaribleCreateOrUpdateOrderPayloadFromJson(json);
	Map<String, dynamic> toJson( ) => _$RaribleCreateOrUpdateOrderPayloadToJson(this);



  @JsonKey(name: "@type")
  final String? type;
  final Map<String, dynamic> data;
  final String maker;
  final String? taker;
  final Map<String, dynamic> make;
  final Map<String, dynamic> take;
  final DateTime? startedAt;
  final DateTime endedAt;
  final String salt;
  final String signature;
  final String blockchain;

  const RaribleCreateOrUpdateOrderPayload({
    this.type,
    required this.data,
    required this.maker,
    this.taker,
    required this.make,
    required this.take,
    this.startedAt,
    required this.endedAt,
    required this.salt,
    required this.signature,
    required this.blockchain,
  });
}
