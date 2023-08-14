// ignore_for_file: use_build_context_synchronously

//import packages
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ownerchip_whitelabel/screens/HomeScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/credentials.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:web3dart/crypto.dart';
import 'dart:io' show Platform;
import 'package:sentry/sentry.dart';

//import services
import 'package:ownerchip_whitelabel/services/nfc.services.dart';
import 'package:ownerchip_whitelabel/services/backend.services.dart';
import 'package:ownerchip_whitelabel/services/signature.services.dart';
import 'package:ownerchip_whitelabel/services/providers.services.dart';

//import screens
import 'package:ownerchip_whitelabel/screens/MetadataInputScreen.dart';
import 'package:ownerchip_whitelabel/screens/ChainSelectorScreen.dart';
import 'package:ownerchip_whitelabel/screens/UserScanResultsScreen.dart';

//import widgets
import 'package:ownerchip_whitelabel/widgets/ui/CustomAppBar.dart';
import 'package:ownerchip_whitelabel/widgets/ui/ScanningIndicator.dart';
import 'package:ownerchip_whitelabel/widgets/ui/returnSnackBarWidget.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';

//import misc
import 'package:ownerchip_whitelabel/utils/navigationArguments.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';

class ScanningScreen extends ConsumerStatefulWidget {
  const ScanningScreen({super.key});

  static const routeName = '/scanning';

  @override
  _ScanningScreen createState() => _ScanningScreen();
}

class _ScanningScreen extends ConsumerState<ScanningScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final navArgs =
        ModalRoute.of(context)!.settings.arguments as ScanningScreenArguments;
  }

  Future<void> saveBackendSession(
      String sessionId,
      EthereumAddress cardWalletAddress,
      MsgSignature signature,
      WidgetRef ref) async {
    int sevenDaysInSeconds = 60 * 60 * 24 * 7;
    int sessionExpirationDate = await getSessionExpiration(
        sevenDaysInSeconds, sessionId, cardWalletAddress, signature);

    BackendSession backendSession = BackendSession(sessionId, signature,
        ref.read(userAddressProvider), sessionExpirationDate);

    ref.read(backendSessionProvider.notifier).state = backendSession;

    //persist session date
    final SharedPreferences storage = await SharedPreferences.getInstance();
    final String jsonBackendSession = jsonEncode(backendSession.toJson());
    storage.setString('backendSession', jsonBackendSession);
  }

  void cancelScan() {
    NfcManager.instance.stopSession();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final navArgs =
        ModalRoute.of(context)!.settings.arguments as ScanningScreenArguments;
    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: const CustomAppBar(
          showBackButton: false,
        ),
        body: ScreenBodyLayout(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          withScrollView: false,
          children: [
            (navArgs.nextRoute == MetadataScreen.routeName)
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.loc.initializeChip,
                          style: Theme.of(context).textTheme.displayMedium),
                      RichText(
                        text: TextSpan(
                            text: '${context.loc.step} 1/',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge!
                                .copyWith(fontSize: 18),
                            children: [
                              TextSpan(
                                  text: '2',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall!
                                      .copyWith(fontSize: 18))
                            ]),
                      )
                    ],
                  )
                : Text(context.loc.scanning,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayMedium),
            Column(
              children: [
                SvgPicture.asset(
                  '${dotenv.get('IMAGE_ASSETS_BASE_URL')}/chip_light_blue.svg',
                  width: 70.0,
                ),
                const SizedBox(height: 20),
                const ScanningIndicator(),
                const SizedBox(height: 20),
                SvgPicture.asset(
                  '${dotenv.get('IMAGE_ASSETS_BASE_URL')}/phone.svg',
                  width: 70.0,
                ),
                const SizedBox(height: 30),
                Text(context.loc.scanHint,
                    overflow: TextOverflow.fade,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge!
                    // .copyWith(fontWeight: FontWeight.w400),
                    ),
              ],
            ),
            CustomRoundedButton(
              text: context.loc.cancel,
              onPressed: () => cancelScan(),
            )
          ],
        ));
  }
}
