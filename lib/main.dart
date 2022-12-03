import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:logging/logging.dart';
import 'package:owner_chip_admin_demo/themes/BlueTheme.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:walletconnect_secure_storage/walletconnect_secure_storage.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:web3dart/credentials.dart';
import '../utils/localization.helper.dart';

//screens and widgets
import 'screens/HomeScreen.dart';
import 'screens/ScanningScreen.dart';
import 'screens/UserScanResultsScreen.dart';
import 'screens/MetadataInputScreen.dart';
import 'screens/ChipAlreadyInitializedScreen.dart';
import 'screens/NFTDetailsScreen.dart';
import 'widgets/RestartWidget.dart';
import 'widgets/returnSnackBarWidget.dart';

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
  String initialRoute = HomeScreen.routeName;

  //create wallet connector function
  Future<WalletConnect> createWalletConnector() async {
    WalletConnectSecureStorage sessionStorage = WalletConnectSecureStorage();
    WalletConnectSession? session = await sessionStorage.getSession();

    return WalletConnect(
        bridge: 'https://bridge.walletconnect.org',
        session: session == null || !session!.connected ? null : session,
        sessionStorage: sessionStorage,
        clientMeta: const PeerMeta(
            name: 'OwnerChip Demo',
            description: 'Connecting physical objects to the blockchain.',
            url: 'https://walletconnect.org',
            icons: ["assets/images/oc_logo.png"]));
  }

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
  bool connected = false;
  //connector has to be initialized with WC instance
  WalletConnect connector = WalletConnect(
      bridge: 'https://bridge.walletconnect.org',
      sessionStorage: WalletConnectSecureStorage(),
      clientMeta: const PeerMeta(
          name: 'OwnerChip Demo',
          description: 'Connecting physical objects to the blockchain.',
          url: 'https://walletconnect.org',
          icons: ["assets/images/oc_logo.png"]));

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    //stop scanning for NFC tags in case the app is restarted
    NfcManager.instance.stopSession();
    //after mounting connector is created
    var _connector = await widget.createWalletConnector();
    setState(() {
      connector = _connector;
      connected = connector.connected;
    });
  }

  Future<void> loginWithMetaMask(BuildContext context) async {
    // if (!connector.connected) {
    try {
      var chainId = int.parse(dotenv.get('CHAIN_ID', fallback: '1'));
      var sessionStatus = await connector.connect(
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
      //returnSnackBar
      ScaffoldMessenger.of(context).showSnackBar(returnSnackBarWidget(
          context.loc.errorHeadingSnackBar,
          context.loc.errorConnectingWallet,
          'success'));
      print(e);
    }
    // }
  }

  @override
  Widget build(BuildContext context) {
    connector.on(
        'connect',
        (payload) => {
              //setstate to rerender UI and show wallet icon in appbar correctly
              setState(
                () => {connected = connector.connected},
              )
              //TODO: check what kind of payload is returned here and if sessionData state is necessary
            });

    connector.on(
        'session_update',
        (payload) => {
              //TODO: check what kind of payload is returned here and if sessionData state is necessary
              print("session updated: $payload"),
              setState(() {
                connected = connector.connected;
              })
            });
    connector.on(
        'disconnect',
        (payload) => {
              //restart app, if web3 session is disconnected, to go back to login screen because Navigator cannot be accessed here
              RestartWidget.restartApp(context),

              //setstate to rerender UI and show wallet icon in appbar correctly
              setState(
                () => {connected = false},
              )
            });

    //TODO: fetch colors from .env ??
    var primaryColor = Color(int.parse("0xFF${dotenv.get('PRIMARY_COLOR')}"));

    return MaterialApp(
      theme: ThemeData(
        primaryColor:
            primaryColor, //Primary Color; Todo write colors to separate file!
        primaryColorLight:
            Color.fromARGB(255, 77, 122, 255), //Primary Color Light
        shadowColor: Color.fromARGB(70, 0, 0, 77), //shadow color
        scaffoldBackgroundColor:
            Color.fromARGB(255, 240, 241, 246), //light blue background color
        textTheme: const TextTheme(
            headline1: TextStyle(
                fontSize: 32.0,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 77, 122, 255)), //primary light color
            headline2: TextStyle(
                fontSize: 32.0,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 25, 35, 90)), //primary color
            headline4: TextStyle(
                fontSize: 20.0,
                color: Color.fromARGB(255, 25, 35, 90)), //primary color
            headline5: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 25, 35, 90)), //primary color
            headline6: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 77, 122, 255)), //primary light color
            bodyText1: TextStyle(
                fontSize: 15.0,
                color: Color.fromARGB(255, 77, 122, 255), //primary light color
                fontWeight: FontWeight.w400),
            bodyText2: TextStyle(
                fontSize: 15.0,
                color: Color.fromARGB(255, 25, 35, 90), //primary color
                fontWeight: FontWeight.w400)),
      ).copyWith(
        extensions: <ThemeExtension<dynamic>>[
          const BlueStyle(
              borderColor: Color.fromARGB(255, 249, 247, 247),
              secondaryShadowColor: Color.fromARGB(50, 0, 0, 21),
              boxDecorationColor: Color.fromARGB(210, 160, 160, 160))
        ],
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      initialRoute: widget.initialRoute,
      routes: {
        HomeScreen.routeName: (context) => HomeScreen(
              connector: connector,
              connected: connected,
              loginWithMetaMask: loginWithMetaMask,
            ),
        ScanningScreen.routeName: (context) => ScanningScreen(
            connector: connector,
            connected: connected,
            loginWithMetaMask: loginWithMetaMask),
        ChipAlreadyInitializedScreen.routeName: (context) =>
            ChipAlreadyInitializedScreen(
                connector: connector,
                connected: connected,
                loginWithMetaMask: loginWithMetaMask),
        MetadataScreen.routeName: (context) => MetadataScreen(
            connector: connector,
            connected: connected,
            loginWithMetaMask: loginWithMetaMask),
        UserScanResultsScreen.routeName: (context) => UserScanResultsScreen(
              connector: connector,
              connected: connected,
              loginWithMetaMask: loginWithMetaMask,
            ),
        NFTDetailsScreen.routeName: (context) => NFTDetailsScreen(
              connector: connector,
              connected: connected,
              loginWithMetaMask: loginWithMetaMask,
            ),
      },
    );
  }
}
