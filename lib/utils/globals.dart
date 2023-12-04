import 'package:flutter/material.dart';

class ScaffoldKey {
  static final GlobalKey<ScaffoldState> _scaffoldKeyMetadataInputScreen =
      GlobalKey<ScaffoldState>();
  static final GlobalKey<ScaffoldState> _scaffoldKeyAnotherScreen =
      GlobalKey<ScaffoldState>();
  static final GlobalKey<ScaffoldState> _scaffoldKeyThirdScreen =
      GlobalKey<ScaffoldState>();
  static final GlobalKey<ScaffoldState> _scaffoldKeyFourthScreen =
      GlobalKey<ScaffoldState>();

  static GlobalKey<ScaffoldState> getScaffoldKey(String screenName) {
    switch (screenName) {
      case 'MetadataInputScreen':
        return _scaffoldKeyMetadataInputScreen;
      case 'UserScanResultsScreen':
        return _scaffoldKeyAnotherScreen;
      case 'TransferScreen':
        return _scaffoldKeyThirdScreen;
      case 'OfferOnMPScreen':
        return _scaffoldKeyFourthScreen;
      default:
        return GlobalKey<ScaffoldState>();
    }
  }
}
