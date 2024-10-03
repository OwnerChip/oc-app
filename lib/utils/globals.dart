import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ScaffoldKey {
  static final Map<String, GlobalKey<ScaffoldState>> _scaffoldKeys = {
    'MetadataInputScreen': GlobalKey<ScaffoldState>(),
    'UserScanResultsScreen': GlobalKey<ScaffoldState>(),
    'TransferScreen': GlobalKey<ScaffoldState>(),
    'OfferOnMPScreen': GlobalKey<ScaffoldState>(),
    'EnterShippingAddressScreen': GlobalKey<ScaffoldState>(),
    'HomeScreen': GlobalKey<ScaffoldState>(),
    'NFTDetailsScreen': GlobalKey<ScaffoldState>(),
    'CreationsPage': GlobalKey<ScaffoldState>(),
  };

  static GlobalKey<ScaffoldState> getScaffoldKey(String screenName) {
    if (_scaffoldKeys.containsKey(screenName)) {
      return _scaffoldKeys[screenName]!;
    } else {
      _scaffoldKeys[screenName] = GlobalKey<ScaffoldState>();
      return _scaffoldKeys[screenName]!;
    }
  }
}

class PopupKey {
  static final GlobalKey<ScaffoldState> _walletConnectPopup =
      GlobalKey<ScaffoldState>();

  static GlobalKey<ScaffoldState> getScaffoldKey(String screenName) {
    switch (screenName) {
      case 'WalletConnect':
        return _walletConnectPopup;
      default:
        return GlobalKey<ScaffoldState>();
    }
  }
}
