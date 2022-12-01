import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:owner_chip_admin_demo/utils/url_generator.service.dart';
import 'package:owner_chip_admin_demo/widgets/addTraitsForm.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'SpinningLoader.dart';
import '../screens/HomeScreen.dart';
import '../utils/localization.helper.dart';
import 'CustomRoundedButton.dart';

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
          // actions: <Widget>[
          //   TextButton(
          //       onPressed: () {
          //         Navigator.pushNamed(context, HomeScreen.routeName);
          //       },
          //       child: Text(context.loc.cancel)),
          // ],
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

void showWalletConnectPopup(
    BuildContext context, WalletConnect connector, loginFunction) {
  showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Center(child: Text(context.loc.noWalletConnected)),
          content: CustomRoundedButton(
              text: context.loc.connectWallet,
              onPressed: () =>
                  {loginFunction(context), Navigator.pop(context)}),
        );
      });
}

// only to be called with a connected wallet!
void showWalletConnectedPopup(BuildContext context, WalletConnect connector) {
  String walletAddress = connector.session.accounts[0];

  showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
            title: Center(child: Text("${context.loc.walletConnected}:")),
            content: Column(children: [
              // TODO: height of the box is too large!
              Text("ID: $walletAddress"),
              const SizedBox(height: 15),
              CustomRoundedButton(
                  text: context.loc.disconnectWallet,
                  onPressed: () =>
                      {connector.killSession(), Navigator.pop(context)}),
              const SizedBox(height: 15),
              CustomRoundedButton(
                text: context.loc.showTxHistory,
                onPressed: () => {
                  launchUrl(
                      generateBlockchainExplorerTxHistoryUrl(walletAddress),
                      mode: LaunchMode.externalApplication)
                },
              ),
            ]));
      });
}

void showTraitInputFormDialog(BuildContext context) {
  showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Center(child: Text("${context.loc.addTraits}:")),
          content: TraitForm(), //TODO: pass parent function
        );
      });
}
