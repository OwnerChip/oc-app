//import packages
import 'dart:convert';

import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/screens/GalleryScreen.dart';
import 'package:ownerchip_whitelabel/services/nfc.services.dart';
import 'package:ownerchip_whitelabel/services/wallet.services.dart';
import 'package:ownerchip_whitelabel/services/web3.services.dart';
import 'package:ownerchip_whitelabel/utils/globals.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:sentry/sentry.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';

//import services
import 'package:ownerchip_whitelabel/services/providers/collectionsData.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';

//import widgets
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomAppBar.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomHomeScreenButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomOutlinedButton.dart';

//import screens
import 'package:ownerchip_whitelabel/screens/UserScanResultsScreen.dart';
import 'package:ownerchip_whitelabel/screens/MoreInfoScreen.dart';
import 'package:ownerchip_whitelabel/screens/ChainSelectorScreen.dart';

//import misc
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/utils/navigationArguments.dart';
import 'package:ownerchip_whitelabel/domain/errorDefinitions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  static const routeName = '/home';

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  // setup walletconnect client
  Web3App? wcClient;
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
    await initWcClient(ref, context);

    final storage = await SharedPreferences.getInstance();

    final storedWcSession = storage.getString('session');
    final storedWalletType = storage.getString('walletType');
    final storedUserSession = storage.getString('userSession');
    //check if a session is stored
    if (storedWcSession != null &&
        storedWalletType != null &&
        storedUserSession != null) {
      final wcSession = SessionData.fromJson(jsonDecode(storedWcSession));
      final walletType = WalletType.fromJson(jsonDecode(storedWalletType));
      final backendSession =
          UserSession.fromJson(jsonDecode(storedUserSession));
      //check if the stored session expires in less than three days; if yes, remove it
      //Note: WalletConnect session duration is 7 days
      double nowPlusThreeDays =
          DateTime.now().millisecondsSinceEpoch / 1000 + 3600 * 24 * 3;
      if (wcSession.expiry > nowPlusThreeDays &&
          backendSession.expiryDate > nowPlusThreeDays) {
        ref.read(wcSessionProvider.notifier).state = wcSession;
        ref.read(walletTypeProvider.notifier).state = walletType;
        ref.read(userSessionProvider.notifier).state = backendSession;
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

    if (!shippingPopupIsShown) {
      checkAndShowShippingPopup(context, ref,
          setShippingPopupIsShownState: () => setState(() {
                shippingPopupIsShown = !shippingPopupIsShown;
              }));
    }

    FlutterNativeSplash.remove();
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);

    //check if persisted session is from previous app version; has to be called before _setProviderStatesFromPersistedState()
    _checkAndRemovePersistedStorageDependingOnPreviousAppVersion();
    //read persisted session
    _setProviderStatesFromPersistedState();

    super.initState();
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
    final wc = ref.watch(wcProvider);
    AsyncValue<BlockchainCollectionList> relevantCollections =
        ref.watch(findAllMinterRolesProvider);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBar(
        showBackButton: false,
      ),
      body: ScreenBodyLayout(
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
                            ? CustomRoundedButton(
                                width: 250,
                                text: context.loc.initializeChip,
                                onPressed: () => onButtonPress(true),
                              )
                            : const SizedBox(height: 40),
                        loading: () => SizedBox(
                            height: 40, child: Text(context.loc.loading)),
                        error: (err, stack) => const SizedBox(height: 40)),
                const SizedBox(height: 20),
                CustomRoundedButton(
                  width: 250,
                  text: 'My Collection',
                  onPressed: () =>
                      Navigator.pushNamed(context, GalleryScreen.routeName),
                )
              ],
            ),

            //FOOTER CONTENT
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                //if stebo app show additional button
                dotenv.get('APP_ID') == 'stebo'
                    ? Column(children: [
                        CustomOutlinedButton(
                            buttonText: 'SteboArt',
                            onPressed: () => launchUrl(
                                Uri.parse('https://www.steboart.com'),
                                mode: LaunchMode.externalApplication)),
                        const SizedBox(height: 10),
                      ])
                    : Container(),
                CustomOutlinedButton(
                  buttonText: context.loc.more,
                  onPressed: () =>
                      Navigator.pushNamed(context, MoreInfoScreen.routeName),
                ),
              ],
            )
          ]),
    );
  }
}
