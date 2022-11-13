//boilerplate for stateless widget
import 'package:flutter/material.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';

class AppBarWithLogo extends StatelessWidget with PreferredSizeWidget {
  const AppBarWithLogo(
      {Key? key,
      required this.text,
      required this.loginFunction,
      required this.connectedWallet,
      required this.connector})
      : super(key: key);
  final String text;
  final dynamic loginFunction;
  final String? connectedWallet;
  final WalletConnect connector;
  //necessary to use as appbar because flutter?!
  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

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
          connectedWallet == null && loginFunction != null
              ? IconButton(
                  icon: const Icon(Icons.wallet),
                  color: Colors.black,
                  onPressed: () => loginFunction(context),
                  iconSize: 36,
                )
              : IconButton(
                  icon: const Icon(Icons.logout),
                  color: Colors.black,
                  onPressed: () => {
                    print('button pressed'),
                    connector.killSession(),
                  },
                  iconSize: 36,
                ),
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
