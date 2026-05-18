import 'package:privy_flutter/privy_flutter.dart';
class PrivyNotifierData {
  final PrivyUser? privyUser;
  const PrivyNotifierData({
    this.privyUser,
  });
  factory PrivyNotifierData.initial() {
    return const PrivyNotifierData(
      privyUser: null,
    );
  }
  PrivyNotifierData copyWith({
    PrivyUser? privyUser,
  }) {
    return PrivyNotifierData(
      privyUser: privyUser ?? this.privyUser,
    );
  }
}
