import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/themes/fontSpecs.dart';
import 'package:ownerchip_whitelabel/utils/walletConnect.dart';
import 'package:ownerchip_whitelabel/utils/walletConnect.dart';

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

  WidgetsBinding widgetsBinding =
      WidgetsFlutterBinding.ensureInitialized(); //app lifecycle events listener

  //prevent landscape mode
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  //set initialRoute accordingly
  String initialRoute = HomeScreen.routeName;

  WalletConnect initialConnector = await createWalletConnector();

  runApp(
      //wrapper to enable app restarts
      RestartWidget(
          child: MyApp(
              initialRoute: initialRoute, initialConnector: initialConnector)));
}

class MyApp extends StatefulWidget {
  const MyApp(
      {Key? key, required this.initialRoute, required this.initialConnector})
      : super(key: key);

  final String initialRoute;
  final WalletConnect initialConnector;

  @override
  State<MyApp> createState() => _MyApp();
}

class _MyApp extends State<MyApp> with WidgetsBindingObserver {
  late bool connected;
  late WalletConnect connector;

  //listen to lifecycle events (e.g. resume app from background)
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    setState(() {
      connector = widget.initialConnector;
      connected = widget.initialConnector.connected;
    });
  }

  //remove lifecycle events listener
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  //do stuff on resume
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    //make new wallet connect connector when app is resumed(brought to foreground); necessary to prevent errors with metamask
    if (state == AppLifecycleState.resumed) {
      var wc = await createWalletConnector();
      setState(() {
        connector = wc;
        connected = wc.connected;
      });
    }
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

    return MaterialApp(
      theme: ThemeData(
        primaryColor: CustomColors(dotenv.get('APP_ID')).primaryColor,
        primaryColorLight: CustomColors(dotenv.get('APP_ID')).primaryColorLight,
        shadowColor: CustomColors(dotenv.get('APP_ID')).shadowColor,
        scaffoldBackgroundColor:
            CustomColors(dotenv.get('APP_ID')).scaffoldBackgroundColor,
        cardColor: CustomColors(dotenv.get('APP_ID')).cardColor,
        textTheme: TextTheme(
          headline1: TextStyle(
              fontSize: CustomFonts(dotenv.get('APP_ID')).headline1FontSize,
              fontWeight: CustomFonts(dotenv.get('APP_ID')).headline1FontWeight,
              color: CustomColors(dotenv.get('APP_ID')).headline1Color,
              fontFamily: CustomFonts(dotenv.get('APP_ID')).headline1Font),
          headline2: TextStyle(
              fontSize: CustomFonts(dotenv.get('APP_ID')).headline2FontSize,
              fontFamily: CustomFonts(dotenv.get('APP_ID')).headline2Font,
              fontWeight: CustomFonts(dotenv.get('APP_ID')).headline2FontWeight,
              color: CustomColors(dotenv.get('APP_ID')).headline2Color),
          headline3: TextStyle(
              fontSize: CustomFonts(dotenv.get('APP_ID')).headline3FontSize,
              fontFamily: CustomFonts(dotenv.get('APP_ID')).headline3Font,
              fontWeight: CustomFonts(dotenv.get('APP_ID')).headline3FontWeight,
              color: CustomColors(dotenv.get('APP_ID')).headline3Color),
          headline4: TextStyle(
              fontSize: CustomFonts(dotenv.get('APP_ID')).headline4FontSize,
              fontFamily: CustomFonts(dotenv.get('APP_ID')).headline4Font,
              fontWeight: CustomFonts(dotenv.get('APP_ID')).headline4FontWeight,
              color: CustomColors(dotenv.get('APP_ID')).headline4Color),
          headline5: TextStyle(
              fontSize: CustomFonts(dotenv.get('APP_ID')).headline5FontSize,
              fontFamily: CustomFonts(dotenv.get('APP_ID')).headline5Font,
              fontWeight: CustomFonts(dotenv.get('APP_ID')).headline5FontWeight,
              color: CustomColors(dotenv.get('APP_ID')).headline5Color),
          headline6: TextStyle(
              fontSize: CustomFonts(dotenv.get('APP_ID')).headline6FontSize,
              fontFamily: CustomFonts(dotenv.get('APP_ID')).headline6Font,
              fontWeight: CustomFonts(dotenv.get('APP_ID')).headline6FontWeight,
              color: CustomColors(dotenv.get('APP_ID')).headline6Color),
          bodyText1: TextStyle(
              fontSize: CustomFonts(dotenv.get('APP_ID')).bodyText1FontSize,
              fontFamily: CustomFonts(dotenv.get('APP_ID')).bodyText1Font,
              color: CustomColors(dotenv.get('APP_ID')).bodyText1Color,
              fontWeight:
                  CustomFonts(dotenv.get('APP_ID')).bodyText1FontWeight),
          bodyText2: TextStyle(
              fontSize: CustomFonts(dotenv.get('APP_ID')).bodyText2FontSize,
              fontFamily: CustomFonts(dotenv.get('APP_ID')).bodyText2Font,
              color: CustomColors(dotenv.get('APP_ID')).bodyText2Color,
              fontWeight:
                  CustomFonts(dotenv.get('APP_ID')).bodyText2FontWeight),
        ),
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      initialRoute: widget.initialRoute,
      routes: {
        HomeScreen.routeName: (context) => HomeScreen(
              connector: connector,
              connected: connected,
            ),
        ScanningScreen.routeName: (context) => ScanningScreen(
              connector: connector,
              connected: connected,
            ),
        ChipAlreadyInitializedScreen.routeName: (context) =>
            ChipAlreadyInitializedScreen(
              connector: connector,
              connected: connected,
            ),
        MetadataScreen.routeName: (context) => MetadataScreen(
              connector: connector,
              connected: connected,
            ),
        UserScanResultsScreen.routeName: (context) => UserScanResultsScreen(
              connector: connector,
              connected: connected,
            ),
        NFTDetailsScreen.routeName: (context) => NFTDetailsScreen(
              connector: connector,
              connected: connected,
            ),
      },
    );
  }
}
