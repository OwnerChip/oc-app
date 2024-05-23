
import 'package:json_annotation/json_annotation.dart';

class BigIntJsonConverter implements JsonConverter<BigInt, String> {
  const BigIntJsonConverter();

  @override
  BigInt fromJson(String json) {
    return BigInt.parse(json);
  }

  @override
  String toJson(BigInt object) {
    return object.toString();
  }
}