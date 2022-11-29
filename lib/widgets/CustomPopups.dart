import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'SpinningLoader.dart';
import '../screens/HomeScreen.dart';
import '../utils/localization.helper.dart';

void showLoadingPopUp(BuildContext context, String type) {
  var loadingText = "";
  switch (type) {
    case "UPLOAD":
      loadingText = context.loc.uploadingMetadata;
      break;
    case "MINT":
      loadingText = context.loc.mintingToken;
      break;
    case "BURN":
      loadingText = context.loc.burning;
      break;
    default:
      "loading";
  }

  showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Center(child: Text("$loadingText...")),
          content: const SpinningLoader(),
          actions: <Widget>[
            TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, HomeScreen.routeName);
                },
                child: Text(context.loc.cancel)),
          ],
        );
      });
}

void showMintSuccessPopUp(BuildContext context) {
  showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
            title: Center(child: Text(context.loc.mintSuccess)),
            content: SvgPicture.asset(
              'assets/images/success.svg',
              width: 75.0,
              height: 130.0,
            ));
      });
}

void showBurnSuccessPopUp(BuildContext context) {
  showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
            title: Center(child: Text(context.loc.burnedSuccess)),
            content: SvgPicture.asset(
              'assets/images/bin.svg',
              width: 75.0,
              height: 130.0,
            ));
      });
}
