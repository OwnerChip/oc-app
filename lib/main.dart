import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:ownerchip_whitelabel/services/providers.service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ownerchip_whitelabel/themes/themeData.dart';

//screens and widgets
import 'screens/HomeScreen.dart';
import 'screens/ScanningScreen.dart';
import 'screens/UserScanResultsScreen.dart';
import 'screens/MetadataInputScreen.dart';
import 'screens/ChipAlreadyInitializedScreen.dart';
import 'screens/NFTDetailsScreen.dart';
import 'screens/ChainSelectorScreen.dart';
import 'widgets/logic/RestartWidget.dart';

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
  String initialRoute = ChainSelectorScreen.routeName;

  runApp(RestartWidget(
      child: ProviderScope(
          child: MyApp(
    initialRoute: initialRoute,
  ))));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({Key? key, required this.initialRoute}) : super(key: key);

  final String initialRoute;

  @override
  _MyApp createState() => _MyApp();
}

class _MyApp extends ConsumerState<MyApp> with WidgetsBindingObserver {
  //listen to lifecycle events (e.g. resume app from background)
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    ref.read(walletConnectProvider.notifier).resetWalletConnector();
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
    //make new wallet connect connector when app is resumed(brought to foreground); necessary to prevent errors with metamask/walletconnect
    if (state == AppLifecycleState.resumed) {
      ref.read(walletConnectProvider.notifier).resetWalletConnector();
    }
  }

  @override
  Widget build(BuildContext context) {
    var wc = ref.watch(walletConnectProvider);
    wc.on(
        'disconnect',
        (payload) => {
              //restart app, if web3 session is disconnected, to go back to login screen because Navigator cannot be accessed here
              RestartWidget.restartApp(context),
            });

    return MaterialApp(
      theme: CustomThemeData.getThemeData(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      initialRoute: widget.initialRoute,
      routes: {
        HomeScreen.routeName: (context) => const HomeScreen(),
        ScanningScreen.routeName: (context) => const ScanningScreen(),
        ChipAlreadyInitializedScreen.routeName: (context) =>
            const ChipAlreadyInitializedScreen(),
        MetadataScreen.routeName: (context) => const MetadataScreen(),
        UserScanResultsScreen.routeName: (context) =>
            const UserScanResultsScreen(),
        NFTDetailsScreen.routeName: (context) => const NFTDetailsScreen(),
        ChainSelectorScreen.routeName: (context) => const ChainSelectorScreen(),
      },
    );
  }
}
