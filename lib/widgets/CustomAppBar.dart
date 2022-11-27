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
      required this.connectedWallet,
      required this.connector,
      required this.connected,
      this.showBackButton = true})
      : super(key: key);
  final String? text;
  final dynamic loginFunction;
  final String? connectedWallet;
  final WalletConnect connector;
  final bool connected;
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
      leadingWidth: !showBackButton
          ? 100
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
            child: connected
                ? SizedBox(
                    width: 50,
                    height: 50,
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
                    width: 50,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: (() => onButtonPress(context)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          shape: const CircleBorder(),
                          padding: EdgeInsets.all(0)),
                      child: const Icon(Icons.wallet, size: 25),
                    ),
                  )),

        // child: IconButton(
        //   icon: const Icon(Icons.wallet),
        //   color: Colors.white,
        //   onPressed: () => onButtonPress(context),
        //   iconSize: 36,
        //   style: IconButton.styleFrom(
        //       backgroundColor:
        //           Colors.red //Theme.of(context).primaryColor,
        //       ),
        // ))
      ],

      // title: Row(
      //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //   children: [
      //     Row(
      //       children: [
      //         Image.asset(
      //           'assets/images/oc_logo.png',
      //           fit: BoxFit.contain,
      //           height: 32,
      //         ),
      //         Padding(
      //           padding: EdgeInsets.only(left: 15),
      //           child: Text(text,
      //               style: const TextStyle(
      //                 fontFamily: 'Ubuntu',
      //               )),
      //         ),
      //       ],
      //     ),
      //     connected
      //         ? IconButton(
      //             icon: const Icon(Icons.logout),
      //             color: Colors.black,
      //             onPressed: () => onButtonPress(context),
      //             iconSize: 36,
      //           )
      //         : IconButton(
      //             icon: const Icon(Icons.wallet),
      //             color: Colors.black,
      //             onPressed: () => onButtonPress(context),
      //             iconSize: 36,
      //           )
      //   ],
      // ),
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
