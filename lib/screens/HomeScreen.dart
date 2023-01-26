import 'package:ownerchip_whitelabel/screens/MetadataInputScreen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/localization.helper.dart';

// local files
import '../utils/url_generator.service.dart';
import '../utils/utils.dart';
import '../widgets/CustomAppBar.dart';
import 'ScanningScreen.dart';
import 'UserScanResultsScreen.dart';
import '../utils/navigation_arguments.dart';
import '../widgets/ScreenBodyLayout.dart';
import '../widgets/CustomHomeScreenButton.dart';
import '../widgets/CustomRoundedButton.dart';
import '../widgets/returnSnackBarWidget.dart';
import 'package:ownerchip_whitelabel/utils/walletConnect.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/utils/providers.service.dart';

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

    if (mounted) {
      Navigator.pushNamed(context, ScanningScreen.routeName,
          arguments: ScanningScreenArguments(UserScanResultsScreen.routeName));
    }
  } catch (e) {
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

    if (!wc.connected) {
      await startWalletConnection(context, wc);
    }

    if (mounted) {
      Navigator.pushNamed(context, ScanningScreen.routeName,
          arguments: ScanningScreenArguments(MetadataScreen.routeName));
    }
  } catch (e) {
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
        connectedWalletAddress: wc.session.accounts.isEmpty == true
            ? null
            : wc.session.accounts[0].toLowerCase(),
        showBackButton: false,
      ),
      body: ScreenBodyLayout(
          withScrollView: false,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
            const SizedBox(height: 70),
            CustomRoundedButton(
              width: 250,
              text: context.loc.moreInfo,
              onPressed: () => {
                launchUrl(generateLandingPageUrl(),
                    mode: LaunchMode.externalApplication)
              },
            ),
          ]),
    );
  }
}
