//boilerplate for stateless widget
import 'package:flutter/material.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import '../utils/utils.dart';
import '../widgets/returnSnackBarWidget.dart';
import '../utils/localization.helper.dart';
import 'CustomIconButton.dart';

class CustomAppBar extends StatelessWidget with PreferredSizeWidget {
  const CustomAppBar(
      {Key? key,
      this.text,
      required this.loginFunction,
      required this.connectedWalletAddress,
      required this.connector,
      required this.isConnected,
      this.showBackButton = true})
      : super(key: key);
  final String? text;
  final dynamic loginFunction;
  final String? connectedWalletAddress;
  final WalletConnect connector;
  final bool isConnected;
  final bool showBackButton; //valid values: 'back', 'logo'

  //necessary to use as appbar because flutter?!
  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  void onButtonPress(context) async {
    try {
      //check if there is internet connections
      if (!await checkInternetConnection()) {
        throw Exception("No internet connection");
      }
      //if wc bridge is not connected, then reconnect
      if (!connector.bridgeConnected) {
        connector.reconnect();
      }
      //if wallet is connected then kill session, else connect wallet
      if (isConnected) {
        connector.killSession();
      } else {
        loginFunction(context);
      }
    } catch (e) {
      //show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(returnSnackBarWidget(
          "Error",
          "No internet connection",
          //TODO: localize strings
          // context.loc.errorHeadingSnackBar,
          // context.loc.errorNoInternetConnection,
          'error'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      leadingWidth: !showBackButton
          ? 120
          : null, //only change leading width if logo is shown
      leading: Padding(
          padding: EdgeInsets.only(left: 10),
          child: showBackButton
              ? SizedBox(
                  width: 50,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        shape: const CircleBorder(),
                        padding: EdgeInsets.all(0)),
                    child: const Icon(Icons.arrow_back, size: 25),
                  ),
                )
              : Image.asset(
                  'assets/images/oc_logo.png',
                  fit: BoxFit.contain,
                )),
      title: Text(text ?? '',
          style: const TextStyle(
            fontFamily: 'Ubuntu',
          )),
      centerTitle: true,
      actions: [
        Padding(
            padding: EdgeInsets.only(right: 10),
            child: isConnected
                ? SizedBox(
                    width: 48,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: (() => onButtonPress(context)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          shape: const CircleBorder(),
                          padding: EdgeInsets.all(0)),
                      child: const Icon(Icons.logout, size: 25),
                    ),
                  )
                : SizedBox(
                    width: 48,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: (() => onButtonPress(context)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          shape: const CircleBorder(),
                          padding: EdgeInsets.all(0)),
                      child: const Icon(Icons.wallet, size: 25),
                    ),
                  )),
      ],

      titleTextStyle: const TextStyle(
        color: Colors.black,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
    );
  }
}
