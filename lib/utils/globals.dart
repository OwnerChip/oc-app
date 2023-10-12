import 'package:flutter/material.dart';

class ScaffoldKey {
  static final GlobalKey<ScaffoldState> _scaffoldKeyMetadataInputScreen =
      GlobalKey<ScaffoldState>();
  static final GlobalKey<ScaffoldState> _scaffoldKeyAnotherScreen =
      GlobalKey<ScaffoldState>();
  static final GlobalKey<ScaffoldState> _scaffoldKeyThirdScreen =
      GlobalKey<ScaffoldState>();

  static GlobalKey<ScaffoldState> getScaffoldKey(String screenName) {
    switch (screenName) {
      case 'MetadataInputScreen':
        return _scaffoldKeyMetadataInputScreen;
      case 'UserScanResultsScreen':
        return _scaffoldKeyAnotherScreen;
      case 'TransferScreen':
        return _scaffoldKeyThirdScreen;
      default:
        return GlobalKey<ScaffoldState>();
    }
  }
}
