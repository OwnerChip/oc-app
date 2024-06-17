import 'package:json_annotation/json_annotation.dart';
import 'package:ownerchip_whitelabel/domain/walletSignature/walletSignature.dart';

part 'getSessionExpirationPayload.g.dart';

@JsonSerializable(explicitToJson: true)
class GetSessionExpirationPayload {
  factory GetSessionExpirationPayload.fromJson(Map<String, dynamic> json) =>
      _$GetSessionExpirationPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$GetSessionExpirationPayloadToJson(this);

  final String sessionId;
  final String walletAddress;
  final WalletSignature userWalletSignature;

  const GetSessionExpirationPayload({
    required this.sessionId,
    required this.walletAddress,
    required this.userWalletSignature,
  });
}
