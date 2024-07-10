import 'package:json_annotation/json_annotation.dart';

import 'package:web3dart/web3dart.dart';

part 'fcm_token.g.dart';

@JsonSerializable(explicitToJson: true)
class FCMToken {
  factory FCMToken.fromJson(Map<String, dynamic> json) =>
      _$FCMTokenFromJson(json);

  Map<String, dynamic> toJson() => _$FCMTokenToJson(this);

  final int id;
  final String token;
  final String address;
  final DateTime timestamp;

  const FCMToken({
    required this.id,
    required this.token,
    required this.address,
    required this.timestamp,
  });
}
