import 'package:json_annotation/json_annotation.dart';

part 'userAccountDeletionRequestResponse.g.dart';

@JsonSerializable(explicitToJson: true)
class UserAccountDeletionRequestResponse {
  factory UserAccountDeletionRequestResponse.fromJson(
          Map<String, dynamic> json) =>
      _$UserAccountDeletionRequestResponseFromJson(json);

  Map<String, dynamic> toJson() =>
      _$UserAccountDeletionRequestResponseToJson(this);

  final String address;
  final String createdAt;

  const UserAccountDeletionRequestResponse({
    required this.address,
    required this.createdAt,
  });
}
