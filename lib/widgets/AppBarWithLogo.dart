//boilerplate for stateless widget
import 'package:flutter/material.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import '../utils/utils.dart';
import '../widgets/returnSnackBarWidget.dart';
import '../utils/localization.helper.dart';

class AppBarWithLogo extends StatelessWidget with PreferredSizeWidget {
  const AppBarWithLogo(
      {Key? key,
      required this.text,
      required this.loginFunction,
      required this.connectedWallet,
      required this.connector,
      required this.connected})
      : super(key: key);
  final String text;
  final dynamic loginFunction;
  final String? connectedWallet;
  final WalletConnect connector;
  final bool connected;
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
      if (connected) {
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
      centerTitle: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/oc_logo.png',
                fit: BoxFit.contain,
                height: 32,
              ),
              Padding(
                padding: EdgeInsets.only(left: 15),
                child: Text(text,
                    style: const TextStyle(
                      fontFamily: 'Ubuntu',
                    )),
              ),
            ],
          ),
          connected
              ? IconButton(
                  icon: const Icon(Icons.logout),
                  color: Colors.black,
                  onPressed: () => onButtonPress(context),
                  iconSize: 36,
                )
              : IconButton(
                  icon: const Icon(Icons.wallet),
                  color: Colors.black,
                  onPressed: () => onButtonPress(context),
                  iconSize: 36,
                )
        ],
      ),
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
