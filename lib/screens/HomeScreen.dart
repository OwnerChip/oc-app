//import packages
import 'package:nfc_manager/nfc_manager.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/services/scan.services.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:sentry/sentry.dart';

//import services
import 'package:ownerchip_whitelabel/services/providers.services.dart';

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
import 'package:url_launcher/url_launcher.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  static const routeName = '/home';

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

Future<void> onButtonPress(WidgetRef ref, BuildContext context, bool mounted,
    bool isInitialize) async {
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
          context.loc.errorNoNfcReader, 'error'),
    );
  }

  try {
    //check if NFC is deactivated
    if (!await checkNfcReader()) {
      throw CustomException("NFC Reader is not activated");
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

class _HomeScreenState extends ConsumerState<HomeScreen> {
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
                    onTap: () => onButtonPress(ref, context, mounted, false)),
                const SizedBox(height: 40),
                CustomRoundedButton(
                  width: 250,
                  text: context.loc.scanNow,
                  onPressed: () => onButtonPress(ref, context, mounted, false),
                ),
                const SizedBox(height: 20),
                relevantCollections.when(
                    data: (data) => data.hasAnyMinterRole! &&
                            ref.read(userSessionProvider) != null
                        ? CustomRoundedButton(
                            width: 250,
                            text: context.loc.initializeChip,
                            onPressed: () =>
                                onButtonPress(ref, context, mounted, true),
                          )
                        : const SizedBox(height: 40),
                    loading: () =>
                        SizedBox(height: 40, child: Text(context.loc.loading)),
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
                                )),
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
