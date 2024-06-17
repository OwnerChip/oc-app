import 'package:json_annotation/json_annotation.dart';

part 'rariblePrepareOrderTransactionResponse.g.dart';

@JsonSerializable(explicitToJson: true)
class RariblePrepareOrderTransactionResponse {

	factory RariblePrepareOrderTransactionResponse.fromJson(Map<String, dynamic> json) => _$RariblePrepareOrderTransactionResponseFromJson(json);
	Map<String, dynamic> toJson( ) => _$RariblePrepareOrderTransactionResponseToJson(this);

  final String transferProxyAddress;
  final Map<String, dynamic> asset;

  final String value;

  const RariblePrepareOrderTransactionResponse({
    required this.transferProxyAddress,
    required this.asset,
    required this.value,
  });
}
