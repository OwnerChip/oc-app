import 'package:json_annotation/json_annotation.dart';
import 'package:ownerchip_whitelabel/services/rarible/orders/payloads/raribleRecipientPayload.dart';

part 'rariblePrepareOrderTransactionPayload.g.dart';

@JsonSerializable(explicitToJson: true)
class RariblePrepareOrderTransactionPayload {
  factory RariblePrepareOrderTransactionPayload.fromJson(
          Map<String, dynamic> json) =>
      _$RariblePrepareOrderTransactionPayloadFromJson(json);

  Map<String, dynamic> toJson() =>
      _$RariblePrepareOrderTransactionPayloadToJson(this);

  final String maker;

  final String taker;

  final String amount;

  final List<RaribleRecipientPayload> payouts;

  final List<RaribleRecipientPayload> originFees;

  const RariblePrepareOrderTransactionPayload({
    required this.maker,
    required this.taker,
    required this.amount,
    required this.payouts,
    required this.originFees,
  });
}
