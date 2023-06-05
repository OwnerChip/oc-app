//import packages
import 'package:ownerchip_whitelabel/screens/ChainSelectorScreen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry/sentry.dart';

//import services
import 'package:ownerchip_whitelabel/services/providers.service.dart';

//import widgets
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomAppBar.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomHomeScreenButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/returnSnackBarWidget.dart';

//import screens
import 'package:ownerchip_whitelabel/screens/MetadataInputScreen.dart';
import 'package:ownerchip_whitelabel/screens/ScanningScreen.dart';
import 'package:ownerchip_whitelabel/screens/UserScanResultsScreen.dart';

//import misc
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/utils/navigation.arguments.dart';
import 'package:ownerchip_whitelabel/domain/errorDefinitions.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  static const routeName = '/login';

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

void onScanButtonPress(BuildContext context, mounted) async {
  try {
    //check if there is internet connections
    if (!await checkInternetConnection()) {
      throw Exception("No internet connection");
    }

    //check if NFC is deactivated
    if (!await checkNfcReader()) {
      throw CustomException("NFC Reader is not activated");
    }

    if (mounted) {
      Navigator.pushNamed(context, ScanningScreen.routeName,
          arguments: ScanningScreenArguments(UserScanResultsScreen.routeName));
    }
  } on CustomException catch (e, s) {
    await Sentry.captureException(
      e,
      stackTrace: s,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      returnSnackBarWidget(context.loc.errorHeadingSnackBar,
          context.loc.errorNoNfcReader, 'error'),
    );
  } catch (e, s) {
    await Sentry.captureException(
      e,
      stackTrace: s,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      returnSnackBarWidget(context.loc.errorHeadingSnackBar,
          context.loc.errorNoInternetConnection, 'error'),
    );
  }
}

void onInitializeButtonPress(
    BuildContext context, WalletConnect wc, mounted) async {
  try {
    //check if there is internet connections
    if (!await checkInternetConnection()) {
      throw Exception("No internet connection");
    }

    //check if NFC is deactivated
    if (!await checkNfcReader()) {
      throw CustomException("NFC Reader is not activated");
    }

    if (mounted) {
      Navigator.pushNamed(context, ScanningScreen.routeName,
          arguments: ScanningScreenArguments(ChainSelectorScreen.routeName));
    }
  } on CustomException catch (e, s) {
    await Sentry.captureException(
      e,
      stackTrace: s,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      returnSnackBarWidget(context.loc.errorHeadingSnackBar,
          context.loc.errorNoNfcReader, 'error'),
    );
  } catch (e, s) {
    await Sentry.captureException(
      e,
      stackTrace: s,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      returnSnackBarWidget(context.loc.errorHeadingSnackBar,
          context.loc.errorNoInternetConnection, 'error'),
    );
  }
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    WalletConnect wc = ref.watch(walletConnectProvider);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        showBackButton: false,
      ),
      body: ScreenBodyLayout(
          withScrollView: dotenv.get('IS_ADMIN') == 'true' ? true : false,
          mainAxisAlignment: MainAxisAlignment.center,
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
                : const SizedBox(height: 20),
            CustomHomeScreenButton(
                text: context.loc.scanning,
                svgPath:
                    '${dotenv.get('IMAGE_ASSETS_BASE_URL')}/homescreen_button_scan.svg',
                onTap: () => onScanButtonPress(context, mounted)),
            const SizedBox(height: 20),
            dotenv.get('IS_ADMIN') == 'true'
                ? CustomHomeScreenButton(
                    text: context.loc.initializeChip,
                    svgPath:
                        '${dotenv.get('IMAGE_ASSETS_BASE_URL')}/homescreen_button_initialize.svg',
                    onTap: () => onInitializeButtonPress(context, wc, mounted))
                : Container(),
            const SizedBox(height: 20),
            CustomRoundedButton(
              width: 250,
              text: context.loc.moreInfo,
              onPressed: () => {
                launchUrl(Uri.parse(dotenv.get('LANDING_PAGE_URL')),
                    mode: LaunchMode.externalApplication)
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Powered by ',
                  style: TextStyle(
                      color: Theme.of(context).primaryColor, fontSize: 12),
                ),
                GestureDetector(
                  onTap: () => {
                    launchUrl(Uri.parse('https://ownerchip.com'),
                        mode: LaunchMode.externalApplication)
                  },
                  child: Text(
                    'OwnerChip.com',
                    style: TextStyle(
                        decoration: TextDecoration.underline,
                        color: Theme.of(context).primaryColor,
                        fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => {
                launchUrl(Uri.parse(dotenv.get('LEGAL_PAGE_URL')),
                    mode: LaunchMode.externalApplication)
              },
              child: Text(
                context.loc.legal,
                style: TextStyle(
                    decoration: TextDecoration.underline,
                    color: Theme.of(context).primaryColor,
                    fontSize: 12),
              ),
            )
          ]),
    );
  }
}
