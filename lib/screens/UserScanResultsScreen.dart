import 'package:flutter/material.dart';
import '../widgets/AppBarWithLogo.dart';
import '../utils/navigation_arguments.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';

class UserScanResultsScreen extends StatelessWidget {
  const UserScanResultsScreen(
      {super.key, this.connector, this.loginWithMetaMask});
  final WalletConnect? connector;
  final Function? loginWithMetaMask;

  static const routeName = '/user-scan-results';

  @override
  Widget build(BuildContext context) {
    final navArgs = ModalRoute.of(context)!.settings.arguments
        as UserScanResultsScreenArguments;

    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBarWithLogo(
          loginFunction: loginWithMetaMask,
          text: 'Scan results',
          connectedWallet: connector!.session?.accounts!.isEmpty == true
              ? null
              : connector!.session?.accounts![0].toLowerCase(),
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
                        navArgs.chipIsInitialized
                            ? const Text('Chip is initialized',
                                style: TextStyle(fontSize: 18))
                            : const Text('Chip is not initialized',
                                style: TextStyle(fontSize: 18)),
                      ],
                    )),
              ],
            ),
            Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          connector!.session.accounts.isNotEmpty &&
                                  connector!.session.accounts![0]
                                          .toLowerCase() ==
                                      navArgs.nftOwner
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 44,
                                )
                              : const Icon(
                                  Icons.warning,
                                  color: Colors.orange,
                                  size: 44,
                                ),
                          const SizedBox(width: 10),
                        ])),
                Expanded(
                    flex: 7,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        connector!.session!.accounts!.isNotEmpty &&
                                connector!.session.accounts![0].toLowerCase() ==
                                    navArgs.nftOwner
                            ? const Text('You are the owner!',
                                style: TextStyle(fontSize: 18))
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('You are not the owner!',
                                      style: TextStyle(fontSize: 18)),
                                  const SizedBox(height: 3),
                                  connector!.session!.accounts!.isEmpty
                                      ? OutlinedButton(
                                          onPressed: (() => {
                                                loginWithMetaMask!(context),
                                              }),
                                          child: Text('Connect Wallet'))
                                      : Container()
                                ],
                              )
                      ],
                    )),
              ],
            ),
            const SizedBox(height: 100),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey, // background
                ),
                onPressed: () =>
                    {Navigator.pushReplacementNamed(context, '/login')},
                child: Text('Home'))
          ]),
        )));
  }
}
