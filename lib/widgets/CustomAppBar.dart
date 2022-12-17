//boilerplate for stateless widget
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:owner_chip_admin_demo/widgets/CustomPopups.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import '../utils/utils.dart';
import '../widgets/returnSnackBarWidget.dart';
import '../utils/localization.helper.dart';
import 'package:owner_chip_admin_demo/themes/colorSpecs.dart';

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

  //necessary to use because flutter?!
  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

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
                  'assets/images/app_logo.png',
                  fit: BoxFit.contain,
                )),
      title: Text(text ?? '', style: Theme.of(context).textTheme.headline3),
      centerTitle: true,
      actions: [
        Padding(
            padding: EdgeInsets.only(right: 5),
            child: isConnected
                ? Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      IconButton(
                        padding: new EdgeInsets.all(0.0),
                        icon: SvgPicture.asset(
                            "assets/images/wallet_connnected_icon.svg"),
                        color: CustomColors.black,
                        onPressed: () => onButtonPress(context),
                      ),
                      Align(
                        alignment: const Alignment(0.0, 0.95),
                        child: Text(
                          context.loc.disconnect,
                          style: Theme.of(context)
                              .textTheme
                              .bodyText2!
                              .copyWith(fontSize: 12),
                        ),
                      ),
                    ],
                  )
                : Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      IconButton(
                        padding: new EdgeInsets.all(0.0),
                        icon: SvgPicture.asset(
                            "assets/images/wallet_connnect_icon.svg"),
                        color: CustomColors.black,
                        onPressed: () => onButtonPress(context),
                      ),
                      Align(
                        alignment: const Alignment(0.0, 0.95),
                        child: Text(
                          context.loc.connect,
                          style: Theme.of(context)
                              .textTheme
                              .bodyText2!
                              .copyWith(fontSize: 10),
                        ),
                      ),
                    ],
                  ))

        // isConnected
        //     ? GestureDetector(
        //         onTap: () {
        //           showWalletConnectedPopup(context, connector);
        //         },
        //         child: Padding(
        //             padding: EdgeInsets.only(right: 10),
        //             child: SvgPicture.asset(
        //               'assets/images/wallet connnected.svg',
        //               width: 60.0,
        //               height: 60.0,
        //             )))
        //     : GestureDetector(
        //         onTap: () {
        //           showWalletConnectPopup(context, connector, loginFunction);
        //         },
        //         child: Padding(
        //             padding: EdgeInsets.only(right: 10),
        //             child: SvgPicture.asset(
        //               'assets/images/wallet disconnected.svg',
        //               width: 60.0,
        //               height: 60.0,
        //             )))
      ],
      titleTextStyle: Theme.of(context).textTheme.headline3,
      backgroundColor: Colors.transparent,
      elevation: 0,
    );
  }
}
