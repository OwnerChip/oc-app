import 'package:flutter/material.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher_string.dart';

//local imports
import 'NFTDetailsScreen.dart';
import '../widgets/AppBarWithLogo.dart';
import '../utils/navigation_arguments.dart';

class UserScanResultsScreen extends StatelessWidget {
  const UserScanResultsScreen(
      {super.key, this.connector, this.loginWithMetaMask});
  final WalletConnect? connector;
  final Function? loginWithMetaMask;

  static const routeName = '/user-scan-results';

  Future<void> launchWallet() async {
    await launchUrlString(connector!.session.toUri(),
        mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final navArgs = ModalRoute.of(context)!.settings.arguments
        as UserScanResultsScreenArguments;

    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBarWithLogo(
          loginFunction: loginWithMetaMask,
          text: 'Tap results',
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
                        Text('NFT Check: ', style: TextStyle(fontSize: 18)),
                        const SizedBox(height: 15),
                        navArgs.chipIsInitialized
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Chip: Infineon Secora',
                                      style: TextStyle(fontSize: 14)),
                                  Text('ID: ${navArgs.tokenId}',
                                      style: TextStyle(fontSize: 14)),
                                  //display first 5 characters of wallet address as Text
                                  Row(
                                    children: [
                                      Text(
                                          'Chip Wallet: ${navArgs.chipWalletAddress.substring(0, 5)}...',
                                          style: TextStyle(fontSize: 14)),
                                      //icon that copies navargs.nftowner to clipboard
                                      IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: BoxConstraints(),
                                          iconSize: 20,
                                          onPressed: () {
                                            Clipboard.setData(ClipboardData(
                                                text:
                                                    navArgs.chipWalletAddress));
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                                    content: Text(
                                                        'Chip wallet address copied to clipboard')));
                                          },
                                          icon: const Icon(Icons.copy))
                                    ],
                                  ),
                                  //button that navigates to nft details screen
                                  OutlinedButton(
                                      onPressed: () {
                                        print(context);
                                        Navigator.of(context).pushNamed(
                                            NFTDetailsScreen.routeName,
                                            arguments:
                                                NFTDetailsScreenArguments(
                                                    connector,
                                                    loginWithMetaMask,
                                                    navArgs.tokenId,
                                                    navArgs.chipWalletAddress));
                                      },
                                      child: const Text('View NFT Details'))
                                ],
                              )
                            : const Text(
                                'Authenticity NFT does not exist on blockchain.',
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
                          connector!.session.accounts.isEmpty
                              ? //no wallet connected
                              const Icon(
                                  Icons.warning,
                                  color: Colors.orange,
                                  size: 44,
                                )
                              : connector!.session.accounts[0].toLowerCase() ==
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
                        Text('Ownership Check: ',
                            style: const TextStyle(fontSize: 18)),
                        const SizedBox(height: 15),
                        connector!.session.accounts.isEmpty
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('You have no wallet connected!',
                                      style: TextStyle(fontSize: 14)),
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
                            : connector!.session.accounts[0].toLowerCase() ==
                                    navArgs.nftOwner
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                          'You are the owner of this NFT!',
                                          style: TextStyle(fontSize: 14)),
                                      const SizedBox(height: 3),
                                      OutlinedButton(
                                          onPressed: (() => {launchWallet()}),
                                          child:
                                              Text('Open wallet to view NFT'))
                                    ],
                                  )
                                : const Text(
                                    'There is no ownership NFT in your wallet.',
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
                    child: Text('Home')))
          ]),
        )));
  }
}
