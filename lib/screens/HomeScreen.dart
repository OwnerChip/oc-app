//import packages
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:ownerchip_whitelabel/config/wallets.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/screens/GalleryScreen.dart';

//import screens
import 'package:ownerchip_whitelabel/screens/MoreInfoScreen.dart';
import 'package:ownerchip_whitelabel/services/alchemy.services.dart';
import 'package:ownerchip_whitelabel/services/backend/auth/backendAuth.dart';
import 'package:ownerchip_whitelabel/services/backend/backend.services.dart';
import 'package:ownerchip_whitelabel/services/nfc.services.dart';
import 'package:ownerchip_whitelabel/services/providers/app/appNotifier.dart';

//import services
import 'package:ownerchip_whitelabel/services/providers/collectionsData.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/services/providers/websocket/websocketNotifier.dart';
import 'package:ownerchip_whitelabel/services/wallet.services.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';

//import misc
import 'package:ownerchip_whitelabel/utils/utils.dart';

//import widgets
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomHomeScreenButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomOutlinedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/appBar/CustomAppBar.dart';
import 'package:reown_appkit/reown_appkit.dart';
import 'package:sentry/sentry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  static const routeName = '/home';

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  // setup walletconnect client
  ReownAppKitModal? wcClient;

  Future<void>
      _checkAndRemovePersistedStorageDependingOnPreviousAppVersion() async {
    final storage = await SharedPreferences.getInstance();

    final storedAppVersion = storage.getString('appVersion');

    if ((storedAppVersion == null) ||
        (storedAppVersion != dotenv.get('VERSION_NUMBER'))) {
      //remove session and wallet type from storage
      storage.remove('walletType');
      storage.remove('userSession');
    }
    storage.setString('appVersion', dotenv.get('VERSION_NUMBER'));
  }

  Future<void> _setProviderStatesFromPersistedState() async {
    try {
      await initWcClient(ref, context);
    } catch (e, s) {
      await Sentry.captureException(
        e,
        stackTrace: s,
      );
      FlutterNativeSplash.remove();
    }

    final storage = await SharedPreferences.getInstance();

    try {
      final wcService = ref.read(w3mServiceProvider);

      ReownAppKitModalSession? storedWcSession = wcService?.session;
      final storedWalletType = storage.getString('walletType');
      final storedUserSession = storage.getString('userSession');

      //check if a session is stored
      if (storedWalletType != null &&
          ((storedUserSession != null &&
                  UserSession.fromJson(jsonDecode(storedUserSession))
                      .isOwnerCard) ||
              (storedWcSession != null && storedUserSession != null))) {
        final walletType = WalletType.fromJson(jsonDecode(storedWalletType));
        final backendSession =
            UserSession.fromJson(jsonDecode(storedUserSession));

        final me = await BackendAuth.getMe(
          backendSession.jwt.raw,
        ).timeout(const Duration(
          seconds: 8,
        ));

        if (me != null && me.role != backendSession.jwt.role) {
          //remove session and wallet type from storage
          await _clearSession(storage, wcService);
          return;
        }

        if (walletType.type == EWalletType.ownerCard) {
          if (backendSession.expiryDate > BackendAuth.nowPlusThreeHours() &&
              backendSession.jwt.raw.isNotEmpty) {
            ref.read(userAddressProvider.notifier).state =
                backendSession.userWalletAddress;
            ref.read(walletTypeProvider.notifier).state = walletType;
            ref.read(userSessionProvider.notifier).state = backendSession;
            Backend.recreateServices(backendSession.jwt.raw);
            ref.read(websocketProvider.notifier).init();
          } else {
            //remove session and wallet type from storage
            await _clearSession(storage, wcService);
          }
        } else {
          //check if the stored session expires in less than three days; if yes, remove it
          //Note: WalletConnect session duration is 7 days

          if ((storedWcSession?.expiry ?? 0) >
                  BackendAuth.nowPlusThreeHours() &&
              backendSession.expiryDate > BackendAuth.nowPlusThreeHours() &&
              backendSession.jwt.raw.isNotEmpty) {
            ref.read(wcSessionProvider.notifier).state = storedWcSession;
            ref.read(walletTypeProvider.notifier).state = walletType;
            ref.read(userSessionProvider.notifier).state = backendSession;
            Backend.recreateServices(backendSession.jwt.raw);
            ref.read(websocketProvider.notifier).init();
          } else {
            //remove session and wallet type from storage
            await _clearSession(storage, wcService);
          }
        }
      } else {
        //remove session and wallet type from storage
        await _clearSession(storage, wcService);
      }

    } catch (e, st) {
      Sentry.captureException(
        e,
        stackTrace: st,
      );
      talker.error(
          "Error initializing persisted state: $e \n proceeding with guest session.");
      await _clearSession(storage, ref.read(w3mServiceProvider));
    } finally {
      FlutterNativeSplash.remove();
    }
  }

  Future<void> _clearSession(
      SharedPreferences storage, ReownAppKitModal? wcService) async {
    storage.remove('walletType');
    storage.remove('userSession');
    wcService?.disconnect();
    await BackendAuth.initGuestSession().timeout(const Duration(
      seconds: 8,
    ));
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    
    // The version guard must COMPLETE before the persisted session is read,
    // otherwise the two race on SharedPreferences and a stale session can be
    // rehydrated before the wipe lands. initState cannot be async, so chain.
    _checkAndRemovePersistedStorageDependingOnPreviousAppVersion()
        .then((_) => _setProviderStatesFromPersistedState())
        .then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ref.read(appNotifierProvider).appDto == null) {
          ref.read(appNotifierProvider.notifier).init();
        }
      });
    });

    //refreshes alchemy metadata for all collections belonging to app
    makeAlchemyRefreshMetadata();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> makeAlchemyRefreshMetadata() async {
    BlockchainCollectionList collections =
        await ref.read(appCollectionProvider.future);
    for (var chainId in collections.collections.keys) {
      for (var collection in collections.collections[chainId]!) {
        updateAlchemyNftCache(chainId, collection.id);
      }
    }
  }

//do stuff on app resume
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
  }

  Future<void> onButtonPress(bool isInitialize) async {
    try {
      //check if there is internet connections
      if (!await checkInternetConnection()) {
        throw Exception("No internet connection");
      }
    } catch (e, s) {
      await Sentry.captureException(
        e,
        stackTrace: s,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        returnSnackBarWidget(context.loc.errorHeadingSnackBar,
            context.loc.errorNoInternetConnection, 'error'),
      );
      return;
    }

    try {
      //check if NFC is deactivated
      if (!await checkNfcReader()) {
        throw Exception("NFC Reader is not activated");
      }
    } catch (e, s) {
      await Sentry.captureException(
        e,
        stackTrace: s,
      );
      print(e);
      print(s.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        returnSnackBarWidget(context.loc.errorHeadingSnackBar,
            context.loc.errorNoNfcReader, 'error'),
      );
      return;
    }

    if (isInitialize) {
      if (!await checkBackendAvailability()) {
        await Sentry.captureException(
          'backend not available',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          returnSnackBarWidget(context.loc.errorHeadingSnackBar,
              'Server not available.', 'error'),
        );
        return;
      }
    }

    try {
      if (mounted) {
        if (isInitialize) {
          await initializeItem(ref, context);
        } else {
          await scanItem(ref, context);
        }
      }
    } catch (e) {
      try {
        NfcManager.instance.stopSession();
      } catch (_) {
        // Ignore if no active session
      }
      ScaffoldMessenger.of(context).showSnackBar(
        returnSnackBarWidget(
            context.loc.errorHeadingSnackBar, 'Error reading chip.', 'error'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appNotifierProvider);

    AsyncValue<BlockchainCollectionList> relevantCollections =
        ref.watch(findAllMinterRolesProvider);

    if (!app.upgradeShown && app.upgradeRequired) {
      // WidgetsBinding.instance.addPostFrameCallback((_) {
      //   ref.read(appNotifierProvider.notifier).showUpgrade(context);
      // });
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBar(
        showBackButton: false,
      ),
      body: _buildBody(
        context,
        relevantCollections,
      ),
    );
  }

  ScreenBodyLayout _buildBody(
    BuildContext context,
    AsyncValue<BlockchainCollectionList> relevantCollections,
  ) {
    return ScreenBodyLayout(
      withScrollView: false,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      flexSides: 0,
      padding: const EdgeInsets.only(top: 0, bottom: 15),
      children: [
        dotenv.get('BITRISEIO_PACKAGE_NAME') == 'com.ownerchip.internal'
            ? const Text(
                'INTERNAL',
                style: TextStyle(color: Colors.red, fontSize: 20),
              )
            : Container(),

        // MIDDLE CONTENT
        Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomHomeScreenButton(
                text: context.loc.scanning,
                svgPath:
                    '${dotenv.get('IMAGE_ASSETS_BASE_URL')}/homescreen_button_scan.svg',
                onTap: () => onButtonPress(false)),
            const SizedBox(height: 40),
            CustomRoundedButton(
              width: 250,
              text: context.loc.scanNow,
              onPressed: () => onButtonPress(false),
            ),
            const SizedBox(height: 20),
            ref.read(userSessionProvider) == null
                ? Container()
                : relevantCollections.when(
                    data: (data) => data.hasAnyMinterRole! &&
                            ref.read(userSessionProvider) != null
                        ? Padding(
                            padding: EdgeInsets.only(bottom: 20),
                            child: CustomRoundedButton(
                              width: 250,
                              text: context.loc.initializeChip,
                              onPressed: () => onButtonPress(true),
                            ))
                        : Container(),
                    loading: () =>
                        SizedBox(height: 40, child: Text(context.loc.loading)),
                    error: (err, stack) => Container()),
          ],
        ),

        //FOOTER CONTENT
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomOutlinedButton(
              width: 250,
              buttonText: context.loc.myCollection,
              onPressed: () =>
                  Navigator.pushNamed(context, GalleryScreen.routeName),
            ),
            const SizedBox(height: 20),
            //if stebo app show additional button
            dotenv.get('APP_ID') == 'stebo'
                ? Column(children: [
                    CustomOutlinedButton(
                        buttonText: 'SteboArt',
                        onPressed: () => launchUrl(
                            Uri.parse('https://www.steboart.com'),
                            mode: LaunchMode.externalApplication)),
                    const SizedBox(height: 20),
                  ])
                : Container(),
            CustomOutlinedButton(
              buttonText: context.loc.more,
              onPressed: () =>
                  Navigator.pushNamed(context, MoreInfoScreen.routeName),
            ),
          ],
        )
      ],
    );
  }
}
