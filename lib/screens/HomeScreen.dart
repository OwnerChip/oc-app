//import packages
import 'dart:convert';

import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/services/scan.services.dart';
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

  Future<void> _setSessionProviderFromPersistedSession() async {
    await initWcClient(ref, context);

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

    //read persisted session
    _setSessionProviderFromPersistedSession();

    super.initState();
  }

  //remove lifecycle events listener
  // @override
  // void dispose() {
  //   super.dispose();
  //   WidgetsBinding.instance.removeObserver(this);
  //   unsubscribeWcListeners(ref);
  // }

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
      // key: ScaffoldKey.getScaffoldKey('HomeScreen'),
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
            dotenv.get('APP_ID') == 'ownerchip_infineon'
                ? Column(children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                            padding:
                                const EdgeInsets.only(left: 10, bottom: 15),
                            child: Image.asset(
                              'assets/images/ownerchip_infineon/infineon_logo.png',
                              height: 40,
                            ))
                      ],
                    ),
                  ])
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
