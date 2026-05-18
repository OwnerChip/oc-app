import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/services/providers/privy/privyNotifierData.dart';
import 'package:privy_flutter/privy_flutter.dart';
class PrivyNotifier extends Notifier<PrivyNotifierData> {
  @override
  PrivyNotifierData build() {
    return PrivyNotifierData.initial();
  }
  void setPrivyUser(PrivyUser? user) {
    state = state.copyWith(privyUser: user);
  }
  void clear() {
    state = PrivyNotifierData.initial();
  }
}
final privyNotifierProvider =
    NotifierProvider<PrivyNotifier, PrivyNotifierData>(
  PrivyNotifier.new,
);
