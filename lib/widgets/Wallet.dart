// import 'package:artsy_apes/screens/login_screen.dart';
// import 'package:artsy_apes/screens/token_list_screen.dart';
import 'package:flutter/material.dart';

import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:walletconnect_secure_storage/walletconnect_secure_storage.dart';

class Wallet extends StatefulWidget {
  const Wallet({super.key});

  @override
  State<Wallet> createState() => _WalletState();
}

class _WalletState extends State<Wallet> {
  late final WalletConnect connector;

  late final SessionStatus session;

  String _account = "";

  @override
  void initState() {
    super.initState();
    initWalletConnect();
  }

  Future initWalletConnect() async {
    final sessionStorage = WalletConnectSecureStorage();
    final session = await sessionStorage.getSession();

    connector = WalletConnect(
      bridge: 'https://bridge.walletconnect.org',
      session: session,
      sessionStorage: sessionStorage,
      clientMeta: const PeerMeta(
        name: 'WalletConnect',
        description: 'WalletConnect Developer App',
        url: 'https://walletconnect.org',
        icons: [
          'https://gblobscdn.gitbook.com/spaces%2F-LJJeCjcLrr53DcT1Ml7%2Favatar.png?alt=media'
        ],
      ),
    );

    setState(() {
      _account = session?.accounts.first ?? '';
    });

    connector.registerListeners(
      onConnect: (session) => onConnect(),
      onSessionUpdate: (response) => print('Session updated: $response'),
      onDisconnect: () => onDisconnect(),
    );
  }

  void onIconButtonPressed(BuildContext context) async {
    if (!connector.connected) {
      session = await connector.createSession(
        chainId: 80001,
        onDisplayUri: (uri) => {print("URI: $uri"), launchUrl(Uri.parse(uri))},
      );
    } else {
      showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          builder: (BuildContext context) {
            return Container(
                height: 150,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Column(children: [
                  const Spacer(),
                  Text(_account,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.normal,
                      )),
                  const Spacer(),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(280, 40),
                        backgroundColor: const Color(0xFF4F4F4F),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 15),
                      ),
                      onPressed: () {
                        connector.killSession();
                        // Navigator.pushAndRemoveUntil(
                        //     context,
                        //     MaterialPageRoute<void>(builder: (context) => LoginScreen()),
                        //         (Route<dynamic> route) => false);
                      },
                      child: const Text(
                        "Disconnect",
                        style: TextStyle(color: Colors.white, fontSize: 15),
                      )),
                  const Spacer()
                ]));
          });
    }
  }

  void onConnect() {
    debugPrint('Connected: $session');
    setState(() {
      _account = session.accounts.first;
    });
    // setState(() {});
    // Navigator.pushNamedAndRemoveUntil(
    //     context,
    //     TokenListScreen.routeName,
    //     (Route<dynamic> route) => false);
  }

  void onDisconnect() {
    debugPrint('Disconnected');
    setState(() {
      _account = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      child: Text('Connect Wallet'),
      onPressed: () async {
        print("connect wallet pressed");
        onIconButtonPressed(this.context);
      },
    );
  }
}
