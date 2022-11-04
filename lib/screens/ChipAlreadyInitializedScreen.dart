import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'dart:convert';
import '../utils/localization.helper.dart';

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

class ChipAlreadyInitializedScreen extends StatefulWidget {
  const ChipAlreadyInitializedScreen(
      {super.key, required this.connector, this.loginWithMetaMask});
  final WalletConnect? connector;
  final Function? loginWithMetaMask;

  static const routeName = '/scan-already-initialized';

  @override
  State<StatefulWidget> createState() => _ChipAlreadyInitializedState();
}

class _ChipAlreadyInitializedState extends State<ChipAlreadyInitializedScreen> {
  String statusText = "";

  Future<void> _burnToken(Uint8List tokenId) async {
    try {
      final contractAddress = dotenv.env['CONTRACT_ADDRESS'];

      var burnParams = makeBurnParams(
          widget.connector!.session!.accounts[0], contractAddress!, tokenId);

      await launchUrlString(widget.connector!.session.toUri(),
          mode: LaunchMode.externalApplication);
      var txnHash = await widget.connector!.sendCustomRequest(
          method: 'eth_sendTransaction', params: burnParams, id: 1338);

      var txnReceipt = await getTxnReceipt(txnHash);
      if (txnReceipt?.status == true) {
        //this means burn succeeded
        statusText = context.loc.burnedSuccess;
        setState(() {
          statusText;
        });
      } else {
        print(context.loc.burnedError);
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> _burnAndMintToken(Uint8List tokenId) async {
    statusText = "BURN & MINT FEATURE NOT IMPLEMENTED YET!";
    setState(() {
      statusText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final navArgs = ModalRoute.of(context)!.settings.arguments
        as ChipAlreadyInitializedScreenArguments;
    final Uint8List tokenId = navArgs.tokenId!;

    setState(() {
      statusText = context.loc.alreadyLinked;
    });

    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBarWithLogo(
          loginFunction: () => {},
          text: context.loc.initializeChip,
          connectedWallet: widget.connector!.session?.accounts!.isEmpty == true
              ? null
              : widget.connector!.session?.accounts![0].toLowerCase(),
        ),
        body: SafeArea(
            child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(
              statusText,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 50),
            Text('TokenID: ${uint8ListTo32ByteHex(navArgs.tokenId)}'),
            const SizedBox(height: 15),
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton(
                onPressed: () => {
                  launchUrl(generateBlockchainExplorerTokenDetailsUrl(
                      tokenId.toString()))
                },
                child: Text(context.loc.showOnExplorer),
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
                  child: Text(context.loc.showOnOpenSea)),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton(
                  onPressed: () => {_burnToken(tokenId)},
                  child: Text(context.loc.burnToken)),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton(
                  onPressed: () => {_burnAndMintToken(tokenId)},
                  child: Text(context.loc.burnAndMint)),
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
                  child: Text(context.loc.cancel)),
            ),
          ]),
        )));
  }
}
