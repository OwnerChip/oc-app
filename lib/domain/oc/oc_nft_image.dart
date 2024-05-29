import 'package:json_annotation/json_annotation.dart';

part 'oc_nft_image.g.dart';

@JsonSerializable(explicitToJson: true)
class OcNftImage {
  factory OcNftImage.fromJson(Map<String, dynamic> json) =>
      _$OcNftImageFromJson(json);

  Map<String, dynamic> toJson() => _$OcNftImageToJson(this);

  final String? cachedUrl;
  final String? thumbnailUrl;
  final String? pngUrl;
  final String? contentType;
  final int? size;
  final String originalUrl;

  const OcNftImage({
    required this.cachedUrl,
    required this.thumbnailUrl,
    required this.pngUrl,
    required this.contentType,
    required this.size,
    required this.originalUrl,
  });
}
