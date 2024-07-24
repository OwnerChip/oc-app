import 'package:json_annotation/json_annotation.dart';

part 'appVersion.g.dart';

@JsonSerializable(explicitToJson: true)
class AppVersion {
  factory AppVersion.fromJson(Map<String, dynamic> json) =>
      _$AppVersionFromJson(json);

  Map<String, dynamic> toJson() => _$AppVersionToJson(this);

  final int major;
  final int minor;
  final int patch;

  const AppVersion({
    required this.major,
    required this.minor,
    required this.patch,
  });

  factory AppVersion.fromString(String version) {
    final parts = version.split('.');
    if (parts.length != 3) {
      throw Exception('Invalid version string');
    }
    return AppVersion(
      major: int.parse(parts[0]),
      minor: int.parse(parts[1]),
      patch: int.parse(parts[2]),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppVersion &&
          runtimeType == other.runtimeType &&
          major == other.major &&
          minor == other.minor &&
          patch == other.patch;

  @override
  int get hashCode => major.hashCode ^ minor.hashCode ^ patch.hashCode;

  operator <(AppVersion other) {
    if (major < other.major) {
      return true;
    } else if (major == other.major) {
      if (minor < other.minor) {
        return true;
      } else if (minor == other.minor) {
        return patch < other.patch;
      }
    }
    return false;
  }

  operator >(AppVersion other) {
    if (major > other.major) {
      return true;
    } else if (major == other.major) {
      if (minor > other.minor) {
        return true;
      } else if (minor == other.minor) {
        return patch > other.patch;
      }
    }
    return false;
  }
}
