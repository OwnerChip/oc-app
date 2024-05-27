import 'package:ownerchip_whitelabel/domain/myBalance/myBalanceListItem.dart';

class MyBalanceNotifierData {
  final MyBalanceListItem? myBalanceListItem;

  factory MyBalanceNotifierData.initial() {
    return const MyBalanceNotifierData(
      myBalanceListItem: null,
    );
  }

  const MyBalanceNotifierData({
    this.myBalanceListItem,
  });

  MyBalanceNotifierData copyWith({
    MyBalanceListItem? myBalanceListItem,
  }) {
    return MyBalanceNotifierData(
      myBalanceListItem: myBalanceListItem,
    );
  }
}
