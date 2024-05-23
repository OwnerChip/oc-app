import 'package:json_annotation/json_annotation.dart';

part 'shippingInfo.g.dart';

@JsonSerializable(explicitToJson: true)
class ShippingInfo {
  factory ShippingInfo.fromJson(Map<String, dynamic> json) =>
      _$ShippingInfoFromJson(json);

  Map<String, dynamic> toJson() => _$ShippingInfoToJson(this);

  String firstName;
  String lastName;
  String email;
  String phoneNumber;
  String companyName;
  String streetAddress;
  String streetAddress1;
  String city;
  String postalCode;
  String stateOrProvince;
  String countryCode;

  ShippingInfo({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.companyName,
    required this.streetAddress,
    required this.streetAddress1,
    required this.city,
    required this.postalCode,
    required this.stateOrProvince,
    required this.countryCode,
  });
}
