import 'package:json_annotation/json_annotation.dart';
import 'package:ownerchip_whitelabel/services/backend/rarible/payloads/raribleRequestConfig.dart';

part 'makeRaribleRequestPayload.g.dart';

@JsonSerializable(explicitToJson: true)
class MakeRaribleRequestPayload {
  factory MakeRaribleRequestPayload.fromJson(Map<String, dynamic> json) =>
      _$MakeRaribleRequestPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$MakeRaribleRequestPayloadToJson(this);

  final RaribleRequestConfig config;
  final int chainId;

  MakeRaribleRequestPayload({
    required this.config,
    required this.chainId,
  });
}
