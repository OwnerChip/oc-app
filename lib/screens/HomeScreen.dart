//import packages
import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/config/wallets.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/domain/creation/digitalTwinMetadata.dart';
import 'package:ownerchip_whitelabel/domain/jwt/jwt_token.dart';
import 'package:ownerchip_whitelabel/screens/GalleryScreen.dart';
import 'package:ownerchip_whitelabel/screens/creations/CreationsPage.dart';
import 'package:ownerchip_whitelabel/screens/onboarding/OnboardingScreen.dart';
import 'package:ownerchip_whitelabel/services/alchemy.services.dart';
import 'package:ownerchip_whitelabel/services/backend/app/backendApp.dart';
import 'package:ownerchip_whitelabel/services/backend/auth/backendAuth.dart';
import 'package:ownerchip_whitelabel/services/backend/backend.services.dart';
import 'package:ownerchip_whitelabel/services/backend/creation/backendCreation.dart';
import 'package:ownerchip_whitelabel/services/nfc.services.dart';
import 'package:ownerchip_whitelabel/services/providers/app/appNotifier.dart';
import 'package:ownerchip_whitelabel/services/providers/chipData.dart';
import 'package:ownerchip_whitelabel/services/providers/nftData.dart';
import 'package:ownerchip_whitelabel/services/providers/onboardingProvider.dart';
import 'package:ownerchip_whitelabel/services/wallet.services.dart';
import 'package:ownerchip_whitelabel/services/web3.services.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:sentry/sentry.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';

//import services
import 'package:ownerchip_whitelabel/services/providers/collectionsData.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';

//import widgets
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';
import 'package:ownerchip_whitelabel/widgets/ui/appBar/CustomAppBar.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomHomeScreenButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomOutlinedButton.dart';

//import screens
import 'package:ownerchip_whitelabel/screens/MoreInfoScreen.dart';

//import misc
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:web3auth_flutter/web3auth_flutter.dart';
import 'package:web3modal_flutter/services/w3m_service/models/w3m_session.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  static const routeName = '/home';

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  // setup walletconnect client
  Web3App? wcClient;
  bool shippingPopupIsShown = false;

  bool _isScanning = false;

  StreamSubscription? _msgSubscription;

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
          } else {
            //remove session and wallet type from storage
            storage.remove('session');
            storage.remove('walletType');
            storage.remove('userSession');
            wcService?.disconnect();
            await BackendAuth.initGuestSession();
          }
        } else {
          final wcSession = W3MSession.fromJson(jsonDecode(storedWcSession!));

          //check if the stored session expires in less than three days; if yes, remove it
          //Note: WalletConnect session duration is 7 days

          if ((wcSession.expiry ?? 0) > BackendAuth.nowPlusThreeHours() &&
              backendSession.expiryDate > BackendAuth.nowPlusThreeHours() &&
              backendSession.jwt.raw.isNotEmpty) {
            ref.read(wcSessionProvider.notifier).state = wcSession;
            ref.read(walletTypeProvider.notifier).state = walletType;
            ref.read(userSessionProvider.notifier).state = backendSession;
            Backend.recreateServices(backendSession.jwt.raw);
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
    _setProviderStatesFromPersistedState();

    //refreshes alchemy metadata for all collections belonging to app
    makeAlchemyRefreshMetadata();

    initMessaging();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(appNotifierProvider).appDto == null) {
        ref.read(appNotifierProvider.notifier).init();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _msgSubscription?.cancel();
    super.dispose();
  }

  Future<void> initMessaging() async {
    FirebaseMessaging.instance.requestPermission(
      provisional: true,
    );

    _msgSubscription = FirebaseMessaging.onMessage.listen(_onMessageReceived);
    talker.log('Firebase messaging initialized');
  }

  Future<void> _onMessageReceived(RemoteMessage message) async {
    talker.log('Message received: ${message.toMap()}');
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
      // check if already scanning
      if (_isScanning) {
        return;
      }

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
        _isScanning = true;
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
    } finally {
      _isScanning = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appNotifierProvider);

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
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBody(context, relevantCollections),
          app.isLoading
              ? Center(
                  child: Container(
                    color: Colors.black.withOpacity(0.2),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: CustomColors(dotenv.get('APP_ID')).primaryColor,
                      ),
                    ),
                  ),
                )
              : Container(),
          Positioned(
            top: 128,
            left: 32,
            child: Row(
              children: [
                ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        CreationsPage.routeName,
                      );
                    },
                    child: Text("Test"))
              ],
            ),
          )
        ],
      ),
    );
  }

  ScreenBodyLayout _buildBody(BuildContext context,
      AsyncValue<BlockchainCollectionList> relevantCollections) {
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
