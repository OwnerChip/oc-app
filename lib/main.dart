//import packages
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ownerchip_whitelabel/screens/MoreInfoScreen.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/services/walletconnect.services.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

//import screens
import 'screens/HomeScreen.dart';
import 'screens/ScanningScreen.dart';
import 'screens/UserScanResultsScreen.dart';
import 'screens/MetadataInputScreen.dart';
import 'screens/NFTDetailsScreen.dart';
import 'screens/ChainSelectorScreen.dart';
import 'screens/TransferScreen.dart';

//import misc
import 'package:ownerchip_whitelabel/services/providers.service.dart';
import 'package:ownerchip_whitelabel/themes/themeData.dart';
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

  //necessary for app lifecycle events listener
  WidgetsFlutterBinding.ensureInitialized();

  //prevent landscape mode
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  //set initialRoute accordingly
  String initialRoute = HomeScreen.routeName;

  //init splash screen
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  //init sentry
  await SentryFlutter.init((options) {
    options.dsn = dotenv.env['SENTRY_DSN']!;
    options.tracesSampleRate = 1.0;
    options.environment = dotenv.env['BITRISEIO_PACKAGE_NAME']!;
  },
      appRunner: () => runApp(RestartWidget(
              child: ProviderScope(
                  child: MyApp(
            initialRoute: initialRoute,
          )))));
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

    //init walletconnect client
    createWcClient();
  }

  void createWcClient() async {
    Web3App? wcClient = await Web3App.createInstance(
      relayUrl:
          'wss://relay.walletconnect.com', // The relay websocket URL, leave blank to use the default
      projectId: '2c1f8425ead06e944ba87cc51745fcd2',
      metadata: const PairingMetadata(
        name: 'OwnerChip',
        description: 'Connecting physical objects to the blockchain',
        url: 'https://walletconnect.com',
        icons: ['https://avatars.githubusercontent.com/u/37784886'],
      ),
    );
    //set walletconnect client provider
    ref.read(walletConnectProvider2.notifier).state = wcClient;
  }

  //remove lifecycle events listener
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  //do stuff on app resume
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    //make new wallet connect connector when app is resumed(brought to foreground); necessary to prevent errors with metamask/walletconnect
    if (state == AppLifecycleState.resumed) {
      ref.read(walletConnectProvider.notifier).resetWalletConnector();
    }
  }

  @override
  Widget build(BuildContext context) {
    final wc = ref.watch(walletConnectProvider);

    wc.on(
        'disconnect',
        (payload) => {
              //restart app, if web3 session is disconnected, to go back to login screen because Navigator cannot be accessed here
              RestartWidget.restartApp(context),
            });

    //fetch relevant collections here to avoid loading in in later screens
    final AsyncValue<BlockchainCollectionList> relevantCollections =
        ref.watch(findAllMinterRolesProvider);

    // close splash screen
    FlutterNativeSplash.remove();

    return MaterialApp(
      theme: CustomThemeData.getThemeData(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      initialRoute: widget.initialRoute,
      //register all routes
      routes: {
        HomeScreen.routeName: (context) => const HomeScreen(),
        ScanningScreen.routeName: (context) => const ScanningScreen(),
        MetadataScreen.routeName: (context) => const MetadataScreen(),
        UserScanResultsScreen.routeName: (context) =>
            const UserScanResultsScreen(),
        NFTDetailsScreen.routeName: (context) => const NFTDetailsScreen(),
        ChainSelectorScreen.routeName: (context) => const ChainSelectorScreen(),
        MoreInfoScreen.routeName: (context) => const MoreInfoScreen(),
        TransferScreen.routeName: (context) => const TransferScreen(),
      },
    );
  }
}
