import 'package:flutter/material.dart';
import '../widgets/AppBarWithLogo.dart';
import '../utils/navigation_arguments.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'LoginScreen.dart';

class ChipAlreadyInitializedScreen extends StatelessWidget {
  const ChipAlreadyInitializedScreen({super.key, required this.connector});
  final WalletConnect? connector;

  static const routeName = '/scan-already-initialized';

  @override
  Widget build(BuildContext context) {
    final navArgs = ModalRoute.of(context)!.settings.arguments
        as ChipAlreadyInitializedScreenArguments;

    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBarWithLogo(
          loginFunction: () => {},
          text: 'Initialize Chip',
          connectedWallet: connector!.session?.accounts!.isEmpty == true
              ? null
              : connector!.session?.accounts![0].toLowerCase(),
        ),
        body: SafeArea(
            child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text(
              'This chip is already linked to an NFT.',
              style: TextStyle(fontSize: 20),
            ),
            Text('TokenID: ${navArgs.tokenId}'),
            const SizedBox(height: 15),
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton(
                  onPressed: () => {},
                  child: const Text('Show on PolygonScan')),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton(
                  onPressed: () => {}, child: const Text('Show on OpenSea')),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton(
                  onPressed: () => {}, child: const Text('Burn token')),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton(
                  onPressed: () => {}, child: const Text('Burn and Mint')),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey, // background
                  ),
                  onPressed: () =>
                      {Navigator.pushNamed(context, LoginScreen.routeName)},
                  child: const Text('Cancel')),
            ),
          ]),
        )));
  }
}
