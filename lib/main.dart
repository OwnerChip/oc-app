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

  //set initialRoute accordingly
  String initialRoute = LoginScreen.routeName;

  //create wallet connector function
  Future<WalletConnect> createWalletConnector() async {
    WalletConnectSecureStorage sessionStorage = WalletConnectSecureStorage();
    WalletConnectSession? session = await sessionStorage.getSession();

    return WalletConnect(
        bridge: 'https://bridge.walletconnect.org',
        session: session,
        sessionStorage: sessionStorage,
        clientMeta: const PeerMeta(
            name: 'OwnerChip Demo',
            description: 'Connecting physical objects to the blockchain.',
            url: 'https://walletconnect.org',
            icons: ["assets/images/oc_logo.png"]));
  }

  //create connector
  WalletConnect connector = await createWalletConnector();

  runApp(
      //wrapper to enable app restarts
      RestartWidget(
          child: MyApp(
              initialRoute: initialRoute,
              createWalletConnector: createWalletConnector)));
}

class MyApp extends StatefulWidget {
  const MyApp(
      {Key? key,
      required this.initialRoute,
      required this.createWalletConnector})
      : super(key: key);

  final String initialRoute;
  final Function createWalletConnector;

  @override
  State<MyApp> createState() => _MyApp();
}

class _MyApp extends State<MyApp> {
  //connector has to be initialized with WC instance
  WalletConnect connector = WalletConnect(
      bridge: 'https://bridge.walletconnect.org',
      clientMeta: const PeerMeta(
          name: 'OwnerChip Demo',
          description: 'Connecting physical objects to the blockchain.',
          url: 'https://walletconnect.org',
          icons: ["assets/images/oc_logo.png"]));

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();

    //after mounting connector is created
    var _connector = await widget.createWalletConnector();
    setState(() {
      connector = _connector;
    });
  }

  Future loginWithMetaMask(BuildContext context) async {
    if (!connector.connected) {
      try {
        var chainId = int.parse(dotenv.get('CHAIN_ID', fallback: '1'));
        var sessionStatus = await connector.createSession(
            chainId: chainId,
            onDisplayUri: (uri) async {
              await launchUrlString(uri, mode: LaunchMode.externalApplication);
            });

        //save session
        connector.sessionStorage?.store(connector.session);

        //TODO: Test without this code: I think this piece of code is needed but unsure why
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
    connector.on(
        'connect',
        (payload) => {
              //setstate to rerender UI and show wallet icon in appbar correctly
              setState(
                () => {},
              )
              //TODO: check what kind of payload is returned here and if sessionData state is necessary
            });

    connector.on(
        'session_update',
        (payload) => {
              //TODO: check what kind of payload is returned here and if sessionData state is necessary
              print("session updated: $payload"),
            });
    connector.on(
        'disconnect',
        (payload) => {
              //TODO: check what kind of payload is returned here
              //restart app, if web3 session is disconnected, to go back to login screen because Navigator cannot be accessed here
              RestartWidget.restartApp(context),
              NfcManager.instance.stopSession(),
              // connector.sessionStorage?.removeSession(),
              //setstate to rerender UI and show wallet icon in appbar correctly
              setState(
                () => {},
              )
            });

    return MaterialApp(
      //color from hex

      theme: ThemeData(primaryColor: Color.fromARGB(255, 77, 122, 255)),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      initialRoute: widget.initialRoute,
      routes: {
        LoginScreen.routeName: (context) => LoginScreen(
              connector: connector,
              loginWithMetaMask: loginWithMetaMask,
            ),
        ScanningScreen.routeName: (context) => ScanningScreen(
            connector: connector, loginWithMetaMask: loginWithMetaMask),
        ChipAlreadyInitializedScreen.routeName: (context) =>
            ChipAlreadyInitializedScreen(connector: connector),
        MetadataScreen.routeName: (context) => MetadataScreen(
            connector: connector, loginWithMetaMask: loginWithMetaMask),
        UserScanResultsScreen.routeName: (context) => UserScanResultsScreen(
              connector: connector,
              loginWithMetaMask: loginWithMetaMask,
            ),
        NFTDetailsScreen.routeName: (context) => NFTDetailsScreen(
              connector: connector,
              loginWithMetaMask: loginWithMetaMask,
            ),
      },
    );
  }
}
