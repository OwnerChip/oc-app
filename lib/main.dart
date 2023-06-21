//import packages
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ownerchip_whitelabel/domain/eip155.dart';
import 'package:ownerchip_whitelabel/screens/MoreInfoScreen.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
import 'package:ownerchip_whitelabel/config/chains.dart';
import 'package:ownerchip_whitelabel/config/wallets.dart';

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

//root widget
class _MyApp extends ConsumerState<MyApp> with WidgetsBindingObserver {
  // setup walletconnect client
  bool wcIsInitialized = false;
  Web3App? wcClient;

  Future<void> initWcClient() async {
    wcClient = await Web3App.createInstance(
      relayUrl: 'wss://relay.walletconnect.com',
      projectId: dotenv.env['WC_PROJECT_ID']!,
      metadata: const PairingMetadata(
        name: 'OwnerChip',
        description:
            'OwnerChip - Connecting physical objects to the blockchain',
        url: 'https://www.ownerchip.com',
        icons: ['https://avatars.githubusercontent.com/u/116345848'],
      ),
    );
    //set walletconnect client provider
    ref.read(wcProvider.notifier).state = wcClient;

    // Register event handlers
    final events = EIP155.events.values.toList();
    for (int chainId in chainConfig.keys) {
      for (final event in events) {
        wcClient!
            .registerEventHandler(chainId: 'eip155:$chainId', event: event);
      }
    }

    wcClient!.onSessionEvent.subscribe(_onSessionEvent);
    wcClient!.onSessionConnect.subscribe(_onSessionConnect);
    wcClient!.onSessionDelete.subscribe(_onSessionDisconnect);
    wcClient!.onSessionExpire.unsubscribe(_onSessionExpire);

    setState(() {
      wcIsInitialized = true;
    });
  }

  void _onSessionConnect(SessionConnect? args) {
    WalletType? walletType = walletConfig[args?.session.peer.metadata.url];
    ref.watch(walletTypeProvider.notifier).state = walletType;
    ref.watch(wcSessionProvider.notifier).state = args?.session;
    final storage = SharedPreferences.getInstance();
    final session = jsonEncode(args?.session);
    //store session
    storage.then((value) => value.setString('session', session));
    //store wallet type (e.g. trust wallet, metamask, etc.)
    storage.then((value) =>
        value.setString('walletType', jsonEncode(walletType!.toJson())));
  }

  void _onSessionDisconnect(SessionDelete? args) {
    ref.watch(wcSessionProvider.notifier).state = null;
    ref.watch(walletTypeProvider.notifier).state = null;
    //remove session and wallet type
    final storage = SharedPreferences.getInstance();
    storage.then((value) => value.remove('session'));
    storage.then((value) => value.remove('walletType'));
  }

  void _onSessionExpire(SessionExpire? event) {
    if (event?.topic != null) {
      // simply disconnect?
      SessionDelete deleteArgs = SessionDelete(event!.topic);
      _onSessionDisconnect(deleteArgs);
    }
  }

  // handle WC session event
  void _onSessionEvent(SessionEvent? args) {
    if (args?.name == "accountsChanged") {
      // simply disconnect?
      //TODO: remove session from connected wallet as well!
      SessionDelete deleteArgs = SessionDelete(args!.topic);
      _onSessionDisconnect(deleteArgs);
      //TODO: show a popup
    } else {
      //do nothing?
    }
  }

  Future<void> _setSessionProviderFromPersistedSession() async {
    final storage = await SharedPreferences.getInstance();

    final storedSession = storage.getString('session');
    final storedWalletType = storage.getString('walletType');
    //check if a session is stored
    if (storedSession != null && storedWalletType != null) {
      final session = SessionData.fromJson(jsonDecode(storedSession));
      final walletType = WalletType.fromJson(jsonDecode(storedWalletType));
      //check if the stored session is expired
      double nowPlusOneHour =
          DateTime.now().millisecondsSinceEpoch / 1000 + 3600;
      if (session.expiry > nowPlusOneHour) {
        ref.watch(wcSessionProvider.notifier).state = session;
        ref.watch(walletTypeProvider.notifier).state = walletType;
      } else {
        //remove session and wallet type from storage
        storage.remove('session');
        storage.remove('walletType');
      }
    }
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);

    //init walletconnect client
    initWcClient();

    //read persisted session
    _setSessionProviderFromPersistedSession();

    super.initState();
  }

  //remove lifecycle events listener
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    wcClient!.onSessionConnect.unsubscribe(_onSessionConnect);
    wcClient!.onSessionDelete.unsubscribe(_onSessionDisconnect);
    wcClient!.onSessionEvent.unsubscribe(_onSessionEvent);
    super.dispose();
  }

  //do stuff on app resume
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {}

  @override
  Widget build(BuildContext context) {
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
