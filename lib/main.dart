//import packages

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:ownerchip_whitelabel/domain/common/fcmNotificationData.dart';
import 'package:ownerchip_whitelabel/firebase_options.dart';
import 'package:ownerchip_whitelabel/screens/AdminInitCard.dart';
import 'package:ownerchip_whitelabel/screens/CardLostScreen.dart';
import 'package:ownerchip_whitelabel/screens/EnterPukScreen.dart';
import 'package:ownerchip_whitelabel/screens/EnterShippingAddressScreen.dart';
import 'package:ownerchip_whitelabel/screens/GalleryScreen.dart';
import 'package:ownerchip_whitelabel/screens/ListAttachmentsScreen.dart';
import 'package:ownerchip_whitelabel/screens/MoreInfoScreen.dart';
import 'package:ownerchip_whitelabel/screens/PinScreen.dart';
import 'package:ownerchip_whitelabel/screens/creations/CreationsPage.dart';
import 'package:ownerchip_whitelabel/screens/myBalance/MyBalanceScreen.dart';
import 'package:ownerchip_whitelabel/screens/offer/OfferForSaleCreatedTokenScreen.dart';
import 'package:ownerchip_whitelabel/screens/offer/OfferOnMPScreen.dart';
import 'package:ownerchip_whitelabel/screens/onboarding/OnboardingScreen.dart';
import 'package:ownerchip_whitelabel/screens/onboarding/OnboardingScreenUserComplete.dart';
import 'package:ownerchip_whitelabel/screens/onboarding/OnboardingScreenWithSteps.dart';
import 'package:ownerchip_whitelabel/screens/qrCode/QRCodeScannerScreen.dart';
import 'package:ownerchip_whitelabel/services/backend/auth/backendAuth.dart';
import 'package:ownerchip_whitelabel/services/providers/collectionsData.dart';
import 'package:ownerchip_whitelabel/services/providers/creations/creationsData.dart';
import 'package:ownerchip_whitelabel/services/providers/creations/creationsNotifier.dart';
import 'package:ownerchip_whitelabel/services/providers/websocket/websocketNotifier.dart';
import 'package:ownerchip_whitelabel/services/wallet.services.dart';

//import misc
import 'package:ownerchip_whitelabel/themes/themeData.dart';
import 'package:ownerchip_whitelabel/utils/globals.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'screens/AddAttachmentScreen.dart';
import 'screens/ChainSelectorScreen.dart';

//import screens
import 'screens/HomeScreen.dart';
import 'screens/MetadataInputScreen.dart';
import 'screens/NFTDetailsScreen.dart';
import 'screens/TransferScreen.dart';
import 'screens/UserScanResultsScreen.dart';

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

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await BackendAuth.initGuestSession();

  //init sentry
  await SentryFlutter.init((options) {
    options.dsn = kDebugMode ? "" : dotenv.env['SENTRY_DSN']!;
    options.tracesSampleRate = 1.0;
    options.environment =
        kDebugMode ? "" : dotenv.env['BITRISEIO_PACKAGE_NAME']!;
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
  StreamSubscription? _msgSubscription;
  StreamSubscription? _bgSubscription;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    initMessaging();
  }

  Future<void> _onMessageReceived(RemoteMessage message) async {
    talker.log('Message received: ${message.toMap()}');

    final data = FCMNotificationData.fromJson(message.data);

    if (data.isDigitalTwinCreation ||
        data.isDigitalTwinBurn ||
        data.isDigitalTwinTransfer) {
      await ref.read(creationsNotifierProvider.notifier).load();
      ref.read(creationsNotifierProvider.notifier).navigateConditionally(
            navigatorKey.currentContext ?? context,
            data.decodeAsDigitalTwinCreation().walletAddress,
            isFromNotification: true,
          );
    }
  }

  Future<void> initMessaging() async {
    FirebaseMessaging.instance.requestPermission(
      provisional: true,
    );

    _msgSubscription = FirebaseMessaging.onMessage.listen(_onMessageReceived);
    FirebaseMessaging.onBackgroundMessage((message) async {
      _onMessageReceived(message);
    });
    _bgSubscription =
        FirebaseMessaging.onMessageOpenedApp.listen(_onMessageReceived);
    FirebaseMessaging.instance.getInitialMessage().then((initialMessage) {
      if (initialMessage != null) {
        _onMessageReceived(initialMessage);
      }
    });
    talker.log('Firebase messaging initialized');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    talker.log('App lifecycle state changed to $state');

    switch (state) {
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.resumed:
        talker.log('App resumed');
        ref.read(websocketProvider.notifier).onResumedFromBackground();
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.hidden:
        break;
      case AppLifecycleState.paused:
        break;
    }
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _msgSubscription?.cancel();
    _bgSubscription?.cancel();

    unsubscribeWcListeners(ref, context);
  }

  @override
  Widget build(BuildContext context) {
    ref.refresh(findAllMinterRolesProvider);
    return MaterialApp(
      navigatorKey: navigatorKey,
      theme: CustomThemeData.getThemeData(),
      debugShowCheckedModeBanner: false,
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
        // the app will set it to english
        return const Locale('en');
      },
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      initialRoute: widget.initialRoute,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          child: child!,
        );
      },
      routes: {
        HomeScreen.routeName: (context) => const HomeScreen(),
        MetadataScreen.routeName: (context) => const MetadataScreen(),
        UserScanResultsScreen.routeName: (context) =>
            const UserScanResultsScreen(),
        NFTDetailsScreen.routeName: (context) => const NFTDetailsScreen(),
        ChainSelectorScreen.routeName: (context) => const ChainSelectorScreen(),
        MoreInfoScreen.routeName: (context) => const MoreInfoScreen(),
        TransferScreen.routeName: (context) {
          TransferScreenArguments? args = ModalRoute.of(context)!
              .settings
              .arguments as TransferScreenArguments?;

          return TransferScreen(
            digitalTwinMetadata: args?.digitalTwinMetadata,
          );
        },
        AddAttachmentScreen.routeName: (context) => const AddAttachmentScreen(),
        ListAttachmentsScreen.routeName: (context) =>
            const ListAttachmentsScreen(),
        PinScreen.routeName: (context) => const PinScreen(),
        EnterPukScreen.routeName: (context) => const EnterPukScreen(),
        AdminInitCard.routeName: (context) => const AdminInitCard(),
        CardLostScreen.routeName: (context) => const CardLostScreen(),
        OfferOnMPScreen.routeName: (context) => const OfferOnMPScreen(),
        EnterShippingAddressScreen.routeName: (context) =>
            const EnterShippingAddressScreen(),
        GalleryScreen.routeName: (context) => const GalleryScreen(),
        OnboardingScreen.routeName: (context) => const OnboardingScreen(),
        OnboardingScreenWithSteps.routeName: (context) =>
            const OnboardingScreenWithSteps(),
        OnboardingScreenUserComplete.routeName: (context) =>
            const OnboardingScreenUserComplete(),
        MyBalancePage.routeName: (context) => const MyBalancePage(),
        OfferForSaleCreatedTokenScreen.routeName: (context) =>
            const OfferForSaleCreatedTokenScreen(),
        QRCodeScannerScreen.routeName: (context) => const QRCodeScannerScreen(),
        CreationsPage.routeName: (context) => const CreationsPage(),
      },
    );
  }
}
