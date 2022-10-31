import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'dart:convert';

//nfc imports
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/platform_tags.dart';

//web3 imports
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web3dart/crypto.dart';

// import local files
import '../widgets/AppBarWithLogo.dart';
import '../utils/navigation_arguments.dart';
import '../utils/url_generator.service.dart';
import 'LoginScreen.dart';
import '../nfc/commands.dart';
import '../utils/utils.dart';
import '../web3/web3.services.dart';

class ChipAlreadyInitializedScreen extends StatelessWidget {
  const ChipAlreadyInitializedScreen({super.key, required this.connector});
  final WalletConnect? connector;

  static const routeName = '/scan-already-initialized';

  void _burnToken(Uint8List tokenId) async {
    try {
      print("do burn");
      final contractAddress = dotenv.env['CONTRACT_ADDRESS'];

      var burnParams = makeBurnParams(
          connector!.session!.accounts[0], contractAddress!, tokenId);

      await launchUrlString(connector!.session.toUri(),
          mode: LaunchMode.externalApplication);
      var txnHash = await connector!.sendCustomRequest(
          method: 'eth_sendTransaction', params: burnParams, id: 1338);

      var txnReceipt = await getTxnReceipt(txnHash);
      if (txnReceipt?.status == true) {
        //this means burn succeeded
        print('Burned token.');
      } else {
        print("Error burning token.");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final navArgs = ModalRoute.of(context)!.settings.arguments
        as ChipAlreadyInitializedScreenArguments;
    final tokenId = navArgs.tokenId!;

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
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 50),
            Text('TokenID: ${bytesToInt(navArgs.tokenId)}'),
            const SizedBox(height: 15),
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton(
                onPressed: () => {
                  launchUrl(generateBlockchainExplorerTokenDetailsUrl(
                      tokenId.toString()))
                },
                child: const Text('Show on BC Explorer'),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton(
                  onPressed: () => {
                        launchUrl(
                            generateOpenSeaTokenDetailsUrl(tokenId.toString()))
                      },
                  child: const Text('Show on OpenSea')),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton(
                  onPressed: () => {_burnToken(tokenId)},
                  child: const Text('Burn token')),
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
