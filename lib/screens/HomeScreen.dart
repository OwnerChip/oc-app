import 'package:owner_chip_admin_demo/screens/MetadataInputScreen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:flutter/material.dart';
import '../utils/localization.helper.dart';
import 'package:flutter_svg/flutter_svg.dart';

// local files
import '../utils/url_generator.service.dart';
import '../widgets/CustomAppBar.dart';
import 'ScanningScreen.dart';
import 'UserScanResultsScreen.dart';
import '../utils/navigation_arguments.dart';
import '../widgets/ScreenBodyLayout.dart';
import '../widgets/CustomHomeScreenButton.dart';
import '../widgets/CustomRoundedButton.dart';

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
                svgPath: 'assets/images/illustration 1 small-cropped.svg',
                onTap: () => Navigator.pushNamed(
                    context, ScanningScreen.routeName,
                    arguments: ScanningScreenArguments(
                        UserScanResultsScreen.routeName))),
            SizedBox(height: 20),
            CustomHomeScreenButton(
                text: context.loc.initializeChip,
                svgPath: 'assets/images/illustration 2-cropped.svg',
                onTap: widget.connector.connected
                    ? () => Navigator.pushNamed(
                        context, ScanningScreen.routeName,
                        arguments:
                            ScanningScreenArguments(MetadataScreen.routeName))
                    : null),
            SizedBox(height: 70),
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
