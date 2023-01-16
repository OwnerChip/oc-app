import 'package:owner_chip_admin_demo/screens/MetadataInputScreen.dart';
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

class HomeScreen extends StatefulWidget {
  const HomeScreen(
      {Key? key,
      required this.connector,
      this.loginWithMetaMask,
      required this.connected})
      : super(key: key);

  final WalletConnect connector;
  final Function? loginWithMetaMask;
  final bool connected;

  static const routeName = '/login';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

Future<bool> onScanButtonPress(context) async {
  try {
    //check if there is internet connections
    if (!await checkInternetConnection()) {
      throw Exception("No internet connection");
    }

    Navigator.pushNamed(context, ScanningScreen.routeName,
        arguments: ScanningScreenArguments(UserScanResultsScreen.routeName));
    return false;
  } catch (e) {
    return true;
  }
}

Future<bool> onInitializeButtonPress(
    context, isConnected, loginWithMetaMask) async {
  try {
    //check if there is internet connections
    if (!await checkInternetConnection()) {
      throw Exception("No internet connection");
    }

    if (!isConnected) {
      await loginWithMetaMask(context);
    }

    Navigator.pushNamed(context, ScanningScreen.routeName,
        arguments: ScanningScreenArguments(MetadataScreen.routeName));
    return false;
  } catch (e) {
    return true;
  }
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        loginFunction: widget.loginWithMetaMask,
        connectedWalletAddress:
            widget.connector.session.accounts.isEmpty == true
                ? null
                : widget.connector.session.accounts[0].toLowerCase(),
        connector: widget.connector,
        isConnected: widget.connected,
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
                onTap: () async {
                  bool showInternetError = await onScanButtonPress(context);

                  if (showInternetError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      returnSnackBarWidget(context.loc.errorHeadingSnackBar,
                          context.loc.errorNoInternetConnection, 'error'),
                    );
                  }
                }),
            const SizedBox(height: 20),
            CustomHomeScreenButton(
                text: context.loc.initializeChip,
                svgPath:
                    '${dotenv.get('IMAGE_ASSETS_BASE_URL')}/homescreen_button_initialize.svg',
                onTap: () async {
                  bool showInternetError = await onInitializeButtonPress(
                      context, widget.connected, widget.loginWithMetaMask);

                  if (showInternetError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      returnSnackBarWidget(context.loc.errorHeadingSnackBar,
                          context.loc.errorNoInternetConnection, 'error'),
                    );
                  }
                }),
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
