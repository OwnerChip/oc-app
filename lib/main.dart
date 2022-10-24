import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:walletconnect_secure_storage/walletconnect_secure_storage.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

//screens and widgets
import 'screens/LoginScreen.dart';
import 'screens/HomeScreen.dart';
import 'screens/ScanningScreen.dart';
import 'screens/MetadataInputScreen.dart';
import 'screens/ChipAlreadyInitializedScreen.dart';
import 'widgets/RestartWidget.dart';

void main(List<String> args) async {
  await dotenv.load(fileName: ".env");

  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  //prevent landscape mode
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  //check if web3 session exists and set initialRoute accordingly
  String initialRoute =
      (await WalletConnectSecureStorage().getSession() == null)
          ? LoginScreen.routeName
          : HomeScreen.routeName;

  runApp(
      //wrapper to enable app restarts
      RestartWidget(child: MyApp(initialRoute: initialRoute)));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key, required this.initialRoute}) : super(key: key);

  final String initialRoute;

  @override
  State<MyApp> createState() => _MyApp();
}

class _MyApp extends State<MyApp> {
  var sessionData;
  SessionStatus? session;

  var connector = WalletConnect(
      bridge: 'https://bridge.walletconnect.org',
      clientMeta: const PeerMeta(
          name: 'OwnerChip Demo',
          description: 'Connecting physical goods to the blockchain.',
          url: 'https://walletconnect.org',
          icons: [
            'https://files.gitbook.com/v0/b/gitbook-legacy-files/o/spaces%2F-LJJeCjcLrr53DcT1Ml7%2Favatar.png?alt=media'
          ]));

  Future initWalletConnect() async {
    final sessionStorage = WalletConnectSecureStorage();
    final session = await sessionStorage.getSession();

    //overwrite connector if session exists
    setState(() {
      connector = WalletConnect(
          bridge: 'https://bridge.walletconnect.org',
          session: session,
          sessionStorage: sessionStorage,
          clientMeta: const PeerMeta(
              name: 'OwnerChip Demo',
              description: 'Connecting physical goods to the blockchain.',
              url: 'https://walletconnect.org',
              icons: [
                'https://files.gitbook.com/v0/b/gitbook-legacy-files/o/spaces%2F-LJJeCjcLrr53DcT1Ml7%2Favatar.png?alt=media'
              ]));
    });
  }

  loginWithMetaMask(BuildContext context) async {
    if (!connector.connected) {
      try {
        var chainId = int.parse(dotenv.get('CHAIN_ID', fallback: '1'));
        await connector.createSession(
            chainId: chainId,
            onDisplayUri: (uri) async {
              await launchUrlString(uri, mode: LaunchMode.externalApplication);
            });
        setState(() {});
        if (!mounted) {
          return;
        }
      } catch (e) {
        print(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    connector!.on(
        'connect',
        (payload) => {
              //TODO: check what kind of payload is returned here and if sessionData state is necessary
              setState(() {
                sessionData = payload;
              })
            });

    connector!.on(
        'session_update',
        (payload) => {
              //TODO: check what kind of payload is returned here and if sessionData state is necessary
              print("session updated: $payload"),
              setState(() {
                sessionData = payload;
              })
            });
    connector!.on(
        'disconnect',
        (payload) => {
              //TODO: check what kind of payload is returned here
              //restart app, if web3 session is disconnected, to go back to login screen because Navigator cannot be accessed here
              RestartWidget.restartApp(context),
              NfcManager.instance.stopSession()
            });
    return MaterialApp(
      initialRoute: widget.initialRoute,
      routes: {
        LoginScreen.routeName: (context) => LoginScreen(
              connector: connector,
              loginWithMetaMask: loginWithMetaMask,
            ),
        HomeScreen.routeName: (context) => HomeScreen(connector: connector),
        ScanningScreen.routeName: (context) => ScanningScreen(
            connector: connector, loginWithMetaMask: loginWithMetaMask),
        ChipAlreadyInitializedScreen.routeName: (context) =>
            ChipAlreadyInitializedScreen(connector: connector),
        MetadataScreen.routeName: (context) =>
            MetadataScreen(connector: connector),
      },
    );
  }
}
