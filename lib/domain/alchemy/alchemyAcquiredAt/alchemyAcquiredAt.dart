import 'package:json_annotation/json_annotation.dart';
import 'package:ownerchip_whitelabel/domain/converters/dateIso8601NullSafetyJsonConverter.dart';

part 'alchemyAcquiredAt.g.dart';

@JsonSerializable(explicitToJson: true)
class AcquiredAt {
  factory AcquiredAt.fromJson(Map<String, dynamic> json) =>
      _$AcquiredAtFromJson(json);

  Map<String, dynamic> toJson() => _$AcquiredAtToJson(this);

  @DateIso8601NullSafetyJsonConverter()
  DateTime? blockTimestamp;
  int? blockNumber;

  AcquiredAt({
    this.blockTimestamp,
    this.blockNumber,
  });
}
