import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ScaffoldKey {
  static final GlobalKey<ScaffoldState> _scaffoldKeyFirstScreen =
      GlobalKey<ScaffoldState>();
  static final GlobalKey<ScaffoldState> _scaffoldKeySecondScreen =
      GlobalKey<ScaffoldState>();
  static final GlobalKey<ScaffoldState> _scaffoldKeyThirdScreen =
      GlobalKey<ScaffoldState>();
  static final GlobalKey<ScaffoldState> _scaffoldKeyFourthScreen =
      GlobalKey<ScaffoldState>();
  static final GlobalKey<ScaffoldState> _scaffoldKeyFifthScreen =
      GlobalKey<ScaffoldState>();
  static final GlobalKey<ScaffoldState> _scaffoldKeySixthScreen =
      GlobalKey<ScaffoldState>();

  static final GlobalKey<ScaffoldState> _scaffoldKeySeventhScreen =
      GlobalKey<ScaffoldState>();

  static GlobalKey<ScaffoldState> getScaffoldKey(String screenName) {
    switch (screenName) {
      case 'MetadataInputScreen':
        return _scaffoldKeyFirstScreen;
      case 'UserScanResultsScreen':
        return _scaffoldKeySecondScreen;
      case 'TransferScreen':
        return _scaffoldKeyThirdScreen;
      case 'OfferOnMPScreen':
        return _scaffoldKeyFourthScreen;
      case 'EnterShippingAddressScreen':
        return _scaffoldKeyFifthScreen;
      case 'HomeScreen':
        return _scaffoldKeySixthScreen;
      case 'NFTDetailsScreen':
        return _scaffoldKeySeventhScreen;
      default:
        return GlobalKey<ScaffoldState>();
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
