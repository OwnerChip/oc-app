//import packages
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ownerchip_whitelabel/domain/eip155.dart';
import 'package:ownerchip_whitelabel/screens/AdminInitCard.dart';
import 'package:ownerchip_whitelabel/screens/CardLostScreen.dart';
import 'package:ownerchip_whitelabel/screens/EnterPukScreen.dart';
import 'package:ownerchip_whitelabel/screens/ListAttachmentsScreen.dart';
import 'package:ownerchip_whitelabel/screens/MoreInfoScreen.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/screens/OfferOnMPScreen.dart';
import 'package:ownerchip_whitelabel/screens/PinScreen.dart';
import 'package:ownerchip_whitelabel/services/wallet.services.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/web3dart.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/services/providers/collectionsData.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';

//import screens
import 'screens/HomeScreen.dart';
import 'screens/UserScanResultsScreen.dart';
import 'screens/MetadataInputScreen.dart';
import 'screens/NFTDetailsScreen.dart';
import 'screens/ChainSelectorScreen.dart';
import 'screens/TransferScreen.dart';
import 'screens/AddAttachmentScreen.dart';

//import misc
import 'package:ownerchip_whitelabel/themes/themeData.dart';
import 'package:ownerchip_whitelabel/config/chains.dart';

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
      appRunner: () => runApp(ProviderScope(
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

//root widget
class _MyApp extends ConsumerState<MyApp> with WidgetsBindingObserver {
  // setup walletconnect client
  Web3App? wcClient;

  Future<void> _setSessionProviderFromPersistedSession() async {
    await initWcClient(ref);

    final storage = await SharedPreferences.getInstance();

    final storedSession = storage.getString('session');
    final storedWalletType = storage.getString('walletType');
    final storedUserSession = storage.getString('userSession');
    //check if a session is stored
    if (storedSession != null &&
        storedWalletType != null &&
        storedUserSession != null) {
      final session = SessionData.fromJson(jsonDecode(storedSession));
      final walletType = WalletType.fromJson(jsonDecode(storedWalletType));
      final userSession = UserSession.fromJson(jsonDecode(storedUserSession));
      //check if the stored session is expired
      double nowPlusOneHour =
          DateTime.now().millisecondsSinceEpoch / 1000 + 3600;
      if (session.expiry > nowPlusOneHour &&
          userSession.expiryDate > nowPlusOneHour) {
        ref.read(wcSessionProvider.notifier).state = session;
        ref.read(walletTypeProvider.notifier).state = walletType;
        ref.read(userSessionProvider.notifier).state = userSession;
      } else {
        //remove session and wallet type from storage
        storage.remove('session');
        storage.remove('walletType');
        storage.remove('userSession');
      }
    } else {
      //remove session and wallet type from storage
      storage.remove('session');
      storage.remove('walletType');
      storage.remove('userSession');
    }
    FlutterNativeSplash.remove();
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);

    //read persisted session
    _setSessionProviderFromPersistedSession();

    super.initState();
  }

  //remove lifecycle events listener
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unsubscribeWcListeners(ref);
    super.dispose();
  }

  //do stuff on app resume
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    //on resume
    if (state == AppLifecycleState.resumed) {}
  }

  @override
  Widget build(BuildContext context) {
    ref.refresh(findAllMinterRolesProvider);
    return MaterialApp(
      theme: CustomThemeData.getThemeData(),
      localeListResolutionCallback: (locales, supportedLocales) {
        print('device locales=$locales supported locales=$supportedLocales');
        print(locales.runtimeType);
        print(supportedLocales.runtimeType);

        if (locales == null) {
          return const Locale('en');
        }

        for (Locale locale in locales) {
          // if device language is supported by the app,
          // just return it to set it as current app language
          for (Locale supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale.languageCode) {
              return locale;
            }
          }
        }

        // if device language is not supported by the app,
        // the app will set it to english but return this to set to Bahasa instead
        return const Locale('en');
      },
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      initialRoute: widget.initialRoute,
      //register all routes
      routes: {
        HomeScreen.routeName: (context) => const HomeScreen(),
        MetadataScreen.routeName: (context) => const MetadataScreen(),
        UserScanResultsScreen.routeName: (context) =>
            const UserScanResultsScreen(),
        NFTDetailsScreen.routeName: (context) => const NFTDetailsScreen(),
        ChainSelectorScreen.routeName: (context) => const ChainSelectorScreen(),
        MoreInfoScreen.routeName: (context) => const MoreInfoScreen(),
        TransferScreen.routeName: (context) => const TransferScreen(),
        AddAttachmentScreen.routeName: (context) => const AddAttachmentScreen(),
        ListAttachmentsScreen.routeName: (context) =>
            const ListAttachmentsScreen(),
        PinScreen.routeName: (context) => const PinScreen(),
        EnterPukScreen.routeName: (context) => const EnterPukScreen(),
        AdminInitCard.routeName: (context) => const AdminInitCard(),
        CardLostScreen.routeName: (context) => const CardLostScreen(),
        OfferOnMPScreen.routeName: (context) => const OfferOnMPScreen(),
      },
    );
  }
}
