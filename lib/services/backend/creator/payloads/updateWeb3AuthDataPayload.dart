import 'package:json_annotation/json_annotation.dart';

part 'updateWeb3AuthDataPayload.g.dart';

@JsonSerializable(explicitToJson: true)
class UpdateWeb3AuthDataPayload {
  factory UpdateWeb3AuthDataPayload.fromJson(Map<String, dynamic> json) =>
      _$UpdateWeb3AuthDataPayloadFromJson(json);

  Map<String, dynamic> toJson() =>
      _$UpdateWeb3AuthDataPayloadToJson(this);

  final String? name;
  final String? email;
  final String? picture;
  final String providerType;

  const UpdateWeb3AuthDataPayload({
    this.name,
    this.email,
    this.picture,
    required this.providerType,
  });
}
