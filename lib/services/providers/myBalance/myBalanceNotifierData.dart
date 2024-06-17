import 'package:ownerchip_whitelabel/domain/myBalance/myBalanceListItem.dart';

class MyBalanceNotifierData {
  final MyBalanceListItem? myBalanceListItem;
  final List<MyBalanceListItem> myBalanceList;

  final bool initialized;

  final bool error;

  factory MyBalanceNotifierData.initial() {
    return MyBalanceNotifierData(
      myBalanceListItem: null,
      myBalanceList: [],
      initialized: false,
      error: false,
    );
  }

  MyBalanceNotifierData({
    this.myBalanceListItem,
    this.initialized = false,
    this.error = false,
    required this.myBalanceList,
  });

  MyBalanceNotifierData copyWith({
    MyBalanceListItem? myBalanceListItem,
    bool? initialized,
    bool? error,
    List<MyBalanceListItem>? myBalanceList,
  }) {
    return MyBalanceNotifierData(
      myBalanceListItem: myBalanceListItem,
      initialized: initialized ?? this.initialized,
      error: error ?? this.error,
      myBalanceList: myBalanceList ?? this.myBalanceList,
    );
  }
}
