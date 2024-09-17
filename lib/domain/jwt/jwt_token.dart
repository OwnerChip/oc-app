import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part 'jwt_token.g.dart';

@JsonSerializable(explicitToJson: true)
class JwtToken {
  factory JwtToken.fromJson(Map<String, dynamic> json) =>
      _$JwtTokenFromJson(json);

  Map<String, dynamic> toJson() => _$JwtTokenToJson(this);

  final String raw;
  final String? walletAddress;
  final String sessionId;
  final String role;
  final int iat;
  final int exp;

  const JwtToken({
    required this.raw,
    required this.walletAddress,
    required this.sessionId,
    required this.role,
    required this.iat,
    required this.exp,
  });

  factory JwtToken.decode(String jwt) {
    try {
      final parts = jwt.split('.');

      if (parts.length != 3) {
        throw Exception('Invalid JWT');
      }

      final payload = _decodeBase64(parts[1]);
      final Map<String, dynamic> payloadMap = json.decode(payload);
      return JwtToken.fromJson({
        "raw": jwt,
        ...payloadMap,
      });
    } catch (e, st) {
      Sentry.captureException(e,
          stackTrace: st,
          hint: Hint.withMap({
            'jwt': jwt,
          }));
      talker.error(e, st);
      rethrow;
    }
  }

  static String _decodeBase64(String str) {
    String output = str.replaceAll('-', '+').replaceAll('_', '/');

    switch (output.length % 4) {
      case 0:
        break;
      case 2:
        output += '==';
        break;
      case 3:
        output += '=';
        break;
      default:
        throw Exception('Illegal base64url string!"');
    }

    return utf8.decode(base64Url.decode(output));
  }

  @override
  String toString() {
    return 'JwtToken{raw: $raw, walletAddress: $walletAddress, sessionId: $sessionId, role: $role, iat: $iat, exp: $exp}';
  }
}
