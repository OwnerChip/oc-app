import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/domain/myBalance/myBalanceListItem.dart';
import 'package:ownerchip_whitelabel/services/providers/myBalance/myBalanceNotifierData.dart';

class MyBalanceNotifier extends Notifier<MyBalanceNotifierData> {
  MyBalanceNotifier() : super();

  @override
  MyBalanceNotifierData build() {
    return MyBalanceNotifierData.initial();
  }

  void setMyBalanceListItem(MyBalanceListItem? myBalanceListItem) {
    state = state.copyWith(myBalanceListItem: myBalanceListItem);
  }
}

final myBalanceNotifierProvider =
    NotifierProvider<MyBalanceNotifier, MyBalanceNotifierData>(
  MyBalanceNotifier.new,
);
