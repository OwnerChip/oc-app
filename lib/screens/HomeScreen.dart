//import packages
import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
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
import 'package:ownerchip_whitelabel/screens/creations/CreationsPage.dart';
import 'package:ownerchip_whitelabel/screens/onboarding/OnboardingScreen.dart';
import 'package:ownerchip_whitelabel/services/alchemy.services.dart';
import 'package:ownerchip_whitelabel/services/backend/auth/backendAuth.dart';
import 'package:ownerchip_whitelabel/services/backend/backend.services.dart';
import 'package:ownerchip_whitelabel/services/nfc.services.dart';
import 'package:ownerchip_whitelabel/services/providers/app/appNotifier.dart';
//import services
import 'package:ownerchip_whitelabel/services/providers/collectionsData.dart';
import 'package:ownerchip_whitelabel/services/providers/creations/creationsData.dart';
import 'package:ownerchip_whitelabel/services/providers/creations/creationsNotifier.dart';
import 'package:ownerchip_whitelabel/services/providers/onboardingProvider.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/services/providers/websocket/websocketNotifier.dart';
import 'package:ownerchip_whitelabel/services/wallet.services.dart';
import 'package:ownerchip_whitelabel/services/web3.services.dart';
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
import 'package:url_launcher/url_launcher.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:web3auth_flutter/web3auth_flutter.dart';

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
  bool shippingPopupIsShown = false;

  Future<void>
      _checkAndRemovePersistedStorageDependingOnPreviousAppVersion() async {
    final storage = await SharedPreferences.getInstance();

    final storedAppVersion = storage.getString('appVersion');

    if ((storedAppVersion == null) ||
        (storedAppVersion != dotenv.get('VERSION_NUMBER'))) {
      //remove session and wallet type from storage
      storage.remove('session');
      storage.remove('walletType');
      storage.remove('userSession');
    }
    storage.setString('appVersion', dotenv.get('VERSION_NUMBER'));
  }

  Future<void> _setProviderStatesFromPersistedState() async {
    try {
      await Future.wait(
        [
          initWcClient(ref, context),
          setupWeb3Auth(),
        ],
        eagerError: true,
      );
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

      final storedWcSession = storage.getString('session');
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
        );

        if (walletType.type == EWalletType.certificateCard ||
            (me != null && me.role != backendSession.jwt.role)) {
          //remove session and wallet type from storage
          storage.remove('session');
          storage.remove('walletType');
          storage.remove('userSession');
          wcService?.disconnect();
          await BackendAuth.initGuestSession();
          return;
        }

        if (walletType.type == EWalletType.web3auth) {
          String? privKey;
          try {
            privKey = await Web3AuthFlutter.getPrivKey();
          } catch (e) {
            await Sentry.captureException(
              e,
            );
          }

          if (privKey != null &&
              backendSession.expiryDate > BackendAuth.nowPlusThreeHours() &&
              backendSession.jwt.raw.isNotEmpty) {
            ref.read(userAddressProvider.notifier).state =
                EthPrivateKey.fromHex(privKey).address;

            ref.read(walletTypeProvider.notifier).state = walletType;
            ref.read(userSessionProvider.notifier).state = backendSession;
            Backend.recreateServices(backendSession.jwt.raw);
            ref.read(websocketProvider.notifier).init();
          } else {
            if (privKey == null) {}
          }
        } else if (walletType.type == EWalletType.ownerCard) {
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
            storage.remove('session');
            storage.remove('walletType');
            storage.remove('userSession');
            wcService?.disconnect();
            await BackendAuth.initGuestSession();
          }
        } else {
          final wcSession = ReownAppKitModalSession.fromMap(jsonDecode(storedWcSession!));

          //check if the stored session expires in less than three days; if yes, remove it
          //Note: WalletConnect session duration is 7 days

          if ((wcSession.expiry ?? 0) > BackendAuth.nowPlusThreeHours() &&
              backendSession.expiryDate > BackendAuth.nowPlusThreeHours() &&
              backendSession.jwt.raw.isNotEmpty) {
            ref.read(wcSessionProvider.notifier).state = wcSession;
            ref.read(walletTypeProvider.notifier).state = walletType;
            ref.read(userSessionProvider.notifier).state = backendSession;
            Backend.recreateServices(backendSession.jwt.raw);
            ref.read(websocketProvider.notifier).init();
          } else {
            //remove session and wallet type from storage
            storage.remove('session');
            storage.remove('walletType');
            storage.remove('userSession');
            wcService?.disconnect();
            await BackendAuth.initGuestSession();
          }
        }
      } else {
        //remove session and wallet type from storage
        storage.remove('session');
        storage.remove('walletType');
        storage.remove('userSession');
        wcService?.disconnect();
        await BackendAuth.initGuestSession();
      }

      if (!shippingPopupIsShown) {
        checkAndShowShippingPopup(context, ref,
            setShippingPopupIsShownState: () => setState(() {
                  shippingPopupIsShown = !shippingPopupIsShown;
                }));
      }
    } catch (e, st) {
      Sentry.captureException(
        e,
        stackTrace: st,
      );
      talker.error(
          "Error initializing persisted state: $e \n proceeding with guest session.");
      storage.remove('session');
      storage.remove('walletType');
      storage.remove('userSession');
      await BackendAuth.initGuestSession();
    } finally {
      FlutterNativeSplash.remove();
    }
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();

    //check if persisted session is from previous app version; has to be called before _setProviderStatesFromPersistedState()
    _checkAndRemovePersistedStorageDependingOnPreviousAppVersion();
    //read persisted session
    _setProviderStatesFromPersistedState().then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          provisional: false,
          sound: true,
        );

        if (ref.read(appNotifierProvider).appDto == null) {
          ref.read(appNotifierProvider.notifier).init().then((_) {
            _checkCreations();
          });
        }
      });
    });

    //refreshes alchemy metadata for all collections belonging to app
    makeAlchemyRefreshMetadata();
  }

  void _checkCreations() {
    ref.read(creationsNotifierProvider.notifier).load().then((_) {
      ref.read(creationsNotifierProvider.notifier).navigateConditionally(
            context,
            null,
          );
    });
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
    if (state == AppLifecycleState.resumed) {
      if (!shippingPopupIsShown) {
        checkAndShowShippingPopup(context, ref,
            setShippingPopupIsShownState: () => setState(() {
                  shippingPopupIsShown = !shippingPopupIsShown;
                }));
      }
    }
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
      NfcManager.instance.stopSession();
      ScaffoldMessenger.of(context).showSnackBar(
        returnSnackBarWidget(
            context.loc.errorHeadingSnackBar, 'Error reading chip.', 'error'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appNotifierProvider);
    final creations = ref.watch(creationsNotifierProvider);

    final wc = ref.watch(wcProvider);
    AsyncValue<BlockchainCollectionList> relevantCollections =
        ref.watch(findAllMinterRolesProvider);

    if (dotenv.get("APP_ID") == "ownerchip") {
      ref.watch(onboardingProvider).maybeWhen(
          data: (data) {
            if (!data.showedTutorial && data.showTutorialNextTime) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(onboardingProvider.notifier).showedTutorial();
                Navigator.of(context).pushNamed(OnboardingScreen.routeName);
              });
            }
          },
          orElse: () {});
    }

    if (!app.upgradeShown && app.upgradeRequired) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(appNotifierProvider.notifier).showUpgrade(context);
      });
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBar(
        showBackButton: false,
      ),
      body: _buildBody(
        context,
        relevantCollections,
        creations,
      ),
    );
  }

  ScreenBodyLayout _buildBody(
    BuildContext context,
    AsyncValue<BlockchainCollectionList> relevantCollections,
    CreationsData creations,
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
            if (creations.initialized &&
                (creations.data != null && creations.data!.isNotEmpty)) ...[
              const SizedBox(height: 20),
              CustomRoundedButton(
                width: 250,
                text: context.loc.nftCreationsHomeScreenButtonTitle,
                onPressed: () =>
                    Navigator.pushNamed(context, CreationsPage.routeName),
              ),
            ]
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
