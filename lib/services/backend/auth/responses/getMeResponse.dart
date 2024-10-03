import 'package:json_annotation/json_annotation.dart';

part 'getMeResponse.g.dart';

@JsonSerializable(explicitToJson: true)
class GetMeResponse {
  factory GetMeResponse.fromJson(Map<String, dynamic> json) =>
      _$GetMeResponseFromJson(json);

  Map<String, dynamic> toJson() => _$GetMeResponseToJson(this);

  final String walletAddress;
  final String role;

  const GetMeResponse({
    required this.walletAddress,
    required this.role,
  });
}
