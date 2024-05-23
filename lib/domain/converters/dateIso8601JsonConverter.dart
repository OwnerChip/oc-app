import 'package:json_annotation/json_annotation.dart';

class DateIso8601JsonConverter implements JsonConverter<DateTime, String> {
  const DateIso8601JsonConverter();

  @override
  DateTime fromJson(String json) {
    return DateTime.parse(json);
  }

  @override
  String toJson(DateTime object) {
    return object.toIso8601String();
  }
}