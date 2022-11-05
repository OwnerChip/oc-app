import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:walletconnect_secure_storage/walletconnect_secure_storage.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:web3dart/credentials.dart';
import '../utils/localization.helper.dart';

//screens and widgets
import 'screens/LoginScreen.dart';
import 'screens/ScanningScreen.dart';
import 'screens/UserScanResultsScreen.dart';
import 'screens/MetadataInputScreen.dart';
import 'screens/ChipAlreadyInitializedScreen.dart';
import 'screens/NFTDetailsScreen.dart';
import 'widgets/RestartWidget.dart';

// setup logger
void _setupLogging() {
  Logger.root.level = Level.WARNING;
  Logger.root.onRecord.listen((event) {
    print('${event.level.name}: ${event.time}: ${event.message}');
  });
}

void main(List<String> args) async {
  _setupLogging();
  await dotenv.load(fileName: ".env");

  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  //prevent landscape mode
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  //check if web3 session exists and set initialRoute accordingly
  String initialRoute = LoginScreen.routeName;

  final sessionStorage = WalletConnectSecureStorage();
  final session = await sessionStorage.getSession();

  WalletConnect connector = WalletConnect(
      bridge: 'https://bridge.walletconnect.org',
      session: session,
      sessionStorage: sessionStorage,
      clientMeta: const PeerMeta(
          name: 'OwnerChip Demo',
          description: 'Connecting physical objects to the blockchain.',
          url: 'https://walletconnect.org',
          icons: ["assets/images/oc_logo.png"]));

  runApp(
      //wrapper to enable app restarts
      RestartWidget(
          child: MyApp(initialRoute: initialRoute, connector: connector)));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key, required this.initialRoute, required this.connector})
      : super(key: key);

  final String initialRoute;
  final WalletConnect connector;

  @override
  State<MyApp> createState() => _MyApp();
}

class _MyApp extends State<MyApp> {
  // var sessionData;
  // SessionStatus? _session;

  // Future initWalletConnect() async {
  //   final sessionStorage = WalletConnectSecureStorage();
  //   final session = await sessionStorage.getSession();

  //   //overwrite connector if session exists
  //   setState(() {
  //     connector = WalletConnect(
  //         bridge: 'https://bridge.walletconnect.org',
  //         session: session,
  //         sessionStorage: sessionStorage,
  //         clientMeta: const PeerMeta(
  //             name: 'OwnerChip Demo',
  //             description: 'Connecting physical goods to the blockchain.',
  //             url: 'https://walletconnect.org',
  //             icons: ["assets/images/walletconnect.png"]));
  //   });
  // }

  Future loginWithMetaMask(BuildContext context) async {
    if (!widget.connector.connected) {
      try {
        var chainId = int.parse(dotenv.get('CHAIN_ID', fallback: '1'));
        var sessionStatus = await widget.connector.createSession(
            chainId: chainId,
            onDisplayUri: (uri) async {
              await launchUrlString(uri, mode: LaunchMode.externalApplication);
            });

        //save session
        await widget.connector.sessionStorage?.store(widget.connector.session);

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
    widget.connector.on(
        'connect',
        (payload) => {
              //TODO: check what kind of payload is returned here and if sessionData state is necessary
            });

    widget.connector.on(
        'session_update',
        (payload) => {
              //TODO: check what kind of payload is returned here and if sessionData state is necessary
              print("session updated: $payload"),
            });
    widget.connector.on(
        'disconnect',
        (payload) => {
              //TODO: check what kind of payload is returned here
              //restart app, if web3 session is disconnected, to go back to login screen because Navigator cannot be accessed here
              RestartWidget.restartApp(context),
              NfcManager.instance.stopSession()
            });

    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      initialRoute: widget.initialRoute,
      routes: {
        LoginScreen.routeName: (context) => LoginScreen(
              connector: widget.connector,
              loginWithMetaMask: loginWithMetaMask,
            ),
        ScanningScreen.routeName: (context) => ScanningScreen(
            connector: widget.connector, loginWithMetaMask: loginWithMetaMask),
        ChipAlreadyInitializedScreen.routeName: (context) =>
            ChipAlreadyInitializedScreen(connector: widget.connector),
        MetadataScreen.routeName: (context) => MetadataScreen(
            connector: widget.connector, loginWithMetaMask: loginWithMetaMask),
        UserScanResultsScreen.routeName: (context) => UserScanResultsScreen(
              connector: widget.connector,
              loginWithMetaMask: loginWithMetaMask,
            ),
        NFTDetailsScreen.routeName: (context) => NFTDetailsScreen(
              connector: widget.connector,
              loginWithMetaMask: loginWithMetaMask,
            ),
      },
    );
  }
}
