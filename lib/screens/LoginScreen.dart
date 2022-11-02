import 'package:url_launcher/url_launcher.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flutter/material.dart';

// local files
import '../utils/url_generator.service.dart';
import '../widgets/AppBarWithLogo.dart';
import 'ScanningScreen.dart';
import 'UserScanResultsScreen.dart';
import '../utils/navigation_arguments.dart';

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
        text: 'OwnerChip Admin',
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
              height: 150,
              child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(
                      context, ScanningScreen.routeName,
                      arguments: ScanningScreenArguments('',
                          'Initialize Chip (1/3)')), //TODO: Do i need to pass empty string first argument here?
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.auto_fix_high, size: 50),
                      SizedBox(height: 10),
                      Text('Initialize Chip'),
                    ],
                  )),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: 200,
              height: 150,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(
                    context, ScanningScreen.routeName,
                    arguments: ScanningScreenArguments(
                        UserScanResultsScreen.routeName,
                        'Searching for chip...')),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.tap_and_play, size: 50),
                    SizedBox(height: 10),
                    Text('Tap an item'),
                  ],
                ),
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
                onPressed: () => {launchUrl(generateLandingPageUrl())},
                child: const Text('More Information'),
              ),
            ),
          ),
        ]),
      )),
    );
  }
}
