import 'package:json_annotation/json_annotation.dart';

part 'alchemyNftAssetImage.g.dart';

@JsonSerializable(explicitToJson: true)
class AlchemyNftAssetImage {
  factory AlchemyNftAssetImage.fromJson(Map<String, dynamic> json) =>
      _$AlchemyNftAssetImageFromJson(json);

  Map<String, dynamic> toJson() => _$AlchemyNftAssetImageToJson(this);

  String? cachedUrl;
  String? thumbnailUrl;
  String pngUrl;
  String? contentType;
  dynamic size; // Using dynamic since the type is not specified
  String? originalUrl;

  AlchemyNftAssetImage({
    required this.cachedUrl,
    this.thumbnailUrl,
    required this.pngUrl,
    required this.contentType,
    this.size,
    required this.originalUrl,
  });
}
