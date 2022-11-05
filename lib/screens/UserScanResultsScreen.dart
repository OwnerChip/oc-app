import 'package:flutter/material.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../utils/localization.helper.dart';

//local imports
import 'NFTDetailsScreen.dart';
import '../widgets/AppBarWithLogo.dart';
import '../utils/navigation_arguments.dart';
import '../widgets/ChipInfo.dart';

class UserScanResultsScreen extends StatelessWidget {
  const UserScanResultsScreen(
      {super.key, required this.connector, this.loginWithMetaMask});
  final WalletConnect connector;
  final Function? loginWithMetaMask;

  static const routeName = '/user-scan-results';

  Future<void> launchWallet() async {
    await launchUrlString('wc:', mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final navArgs = ModalRoute.of(context)!.settings.arguments
        as UserScanResultsScreenArguments;

    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBarWithLogo(
          loginFunction: loginWithMetaMask,
          text: context.loc.tapResults,
          connectedWallet: connector?.session?.accounts!.isEmpty == true
              ? null
              : connector?.session?.accounts![0].toLowerCase(),
          connector: connector,
        ),
        body: SafeArea(
            child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          navArgs.chipIsInitialized
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 44,
                                )
                              : const Icon(
                                  Icons.cancel,
                                  color: Colors.red,
                                  size: 44,
                                ),
                          const SizedBox(width: 10),
                        ])),
                const SizedBox(height: 100),
                Expanded(
                    flex: 7,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${context.loc.nftCheck}: ',
                            style: TextStyle(fontSize: 18)),
                        const SizedBox(height: 15),
                        navArgs.chipIsInitialized
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ChipInfo(
                                      tokenId: navArgs.tokenId,
                                      chipName: 'Secora Infineon',
                                      walletAddress: navArgs.chipWalletAddress),
                                  //button that navigates to nft details screen
                                  OutlinedButton(
                                      onPressed: () {
                                        print(context);
                                        Navigator.of(context).pushNamed(
                                            NFTDetailsScreen.routeName,
                                            arguments:
                                                NFTDetailsScreenArguments(
                                                    loginWithMetaMask,
                                                    navArgs.tokenId,
                                                    navArgs.chipWalletAddress));
                                      },
                                      child: Text(context.loc.viewNftDetails))
                                ],
                              )
                            : Text(context.loc.nftNotFound,
                                style: TextStyle(fontSize: 14)),
                      ],
                    )),
              ],
            ),
            //spacing
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          connector.session.accounts.isEmpty
                              ? //no wallet connected
                              const Icon(
                                  Icons.warning,
                                  color: Colors.orange,
                                  size: 44,
                                )
                              : connector?.session.accounts[0].toLowerCase() ==
                                      navArgs.nftOwner
                                  ? //you are the owner
                                  const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 44,
                                    )
                                  : const Icon(
                                      Icons.cancel,
                                      color: Colors.red,
                                      size: 44,
                                    ),
                          const SizedBox(width: 10),
                        ])),
                Expanded(
                    flex: 7,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${context.loc.checkOwner}: ',
                            style: const TextStyle(fontSize: 18)),
                        const SizedBox(height: 15),
                        connector.session.accounts.isEmpty
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(context.loc.noWalletConnected,
                                      style: TextStyle(fontSize: 14)),
                                  const SizedBox(height: 3),
                                  connector.session!.accounts!.isEmpty
                                      ? OutlinedButton(
                                          onPressed: (() => {
                                                loginWithMetaMask!(context),
                                              }),
                                          child:
                                              Text(context.loc.connectWallet))
                                      : Container()
                                ],
                              )
                            : connector?.session.accounts[0].toLowerCase() ==
                                    navArgs.nftOwner
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(context.loc.youAreNftOwner,
                                          style: TextStyle(fontSize: 14)),
                                      const SizedBox(height: 3),
                                      OutlinedButton(
                                          onPressed: (() => {launchWallet()}),
                                          child: Text(
                                              context.loc.openWalletToView))
                                    ],
                                  )
                                : Text(context.loc.noNftInWallet,
                                    style: TextStyle(fontSize: 14)),
                      ],
                    )),
              ],
            ),
            const SizedBox(height: 100),
            SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey, // background
                    ),
                    onPressed: () =>
                        {Navigator.pushReplacementNamed(context, '/login')},
                    child: Text(context.loc.home)))
          ]),
        )));
  }
}
