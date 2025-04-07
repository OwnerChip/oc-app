import 'package:json_annotation/json_annotation.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:web3dart/crypto.dart';

part 'walletSignature.g.dart';

@JsonSerializable(explicitToJson: true)
class WalletSignature {
  factory WalletSignature.fromJson(Map<String, dynamic> json) =>
      _$WalletSignatureFromJson(json);

  Map<String, dynamic> toJson() => _$WalletSignatureToJson(this);

  factory WalletSignature.fromMsgSignature(MsgSignature sig) {
    return WalletSignature(
      r: convertSignatureParamToHexString(sig.r),
      s: convertSignatureParamToHexString(sig.s),
      v: sig.v,
    );
  }

  factory WalletSignature.build({
    required BigInt r,
    required BigInt s,
    required int v,
  }) {
    return WalletSignature(
      r: convertSignatureParamToHexString(r),
      s: convertSignatureParamToHexString(s),
      v: v,
    );
  }

  final String r;
  final String s;
  final int v;

  const WalletSignature({
    required this.r,
    required this.s,
    required this.v,
  });
}
