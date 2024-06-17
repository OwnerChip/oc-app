import 'package:json_annotation/json_annotation.dart';
import 'package:ownerchip_whitelabel/domain/converters/ethereumAddressJsonConverter.dart';
import 'package:ownerchip_whitelabel/domain/converters/msgSignatureJsonConverter.dart';
import 'package:ownerchip_whitelabel/domain/jwt/jwt_token.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

part 'userSession.g.dart';

@JsonSerializable(explicitToJson: true)
class UserSession {
  factory UserSession.fromJson(Map<String, dynamic> json) =>
      _$UserSessionFromJson(json);

  Map<String, dynamic> toJson() => _$UserSessionToJson(this);

  final String sessionId;

  @MsgSignatureJsonConverter()
  final MsgSignature signatureData;

  @EthereumAddressJsonConverter()
  final EthereumAddress userWalletAddress;
  final bool isOwnerCard;

  int get expiryDate => jwt.exp;

  late final JwtToken jwt;

  UserSession(
    this.sessionId,
    this.signatureData,
    this.userWalletAddress,
    this.isOwnerCard,
    this.jwt,
  );
}
