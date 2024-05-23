import 'package:json_annotation/json_annotation.dart';

class DateIso8601NullSafetyJsonConverter
    implements JsonConverter<DateTime?, String?> {
  const DateIso8601NullSafetyJsonConverter();

  @override
  DateTime? fromJson(String? json) {
    return json == null ? null : DateTime.parse(json);
  }

  @override
  String? toJson(DateTime? object) {
    return object?.toIso8601String();
  }
}
