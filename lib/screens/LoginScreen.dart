import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flutter/material.dart';
import '../widgets/AppBarWithLogo.dart';
import 'ScanningScreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key, this.connector, this.loginWithMetaMask})
      : super(key: key);

  final WalletConnect? connector;
  final Function? loginWithMetaMask;

  static const routeName = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBarWithLogo(
        text: 'OwnerChip Demo Admin App',
        loginFunction: widget.loginWithMetaMask,
        connectedWallet: widget.connector!.session?.accounts!.isEmpty == true
            ? null
            : widget.connector!.session?.accounts![0].toLowerCase(),
      ),
      body: SafeArea(
          child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          widget.connector!.connected
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: 200,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/home'),
                      child: const Text('All functions'),
                    ),
                  ),
                )
              : Container(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, ScanningScreen.routeName),
                child: const Text('Initialize Chip'),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey, // background
                ),
                onPressed: () => {},
                child: const Text('More Information'),
              ),
            ),
          ),
        ]),
      )),
    );
  }
}
