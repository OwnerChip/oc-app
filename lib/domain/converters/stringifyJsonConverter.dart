import 'package:json_annotation/json_annotation.dart';

class StringifyJsonConverter extends JsonConverter<String, dynamic> {
  const StringifyJsonConverter();

  @override
  String fromJson(json) {
    if (json == null) {
      return '';
    }
    return json.toString();
  }

  @override
  dynamic toJson(String object) {
    return object;
  }
}
