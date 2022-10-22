import 'package:flutter/material.dart';
import 'dart:typed_data';

//web3 imports
import 'package:web3dart/crypto.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';

//nfc imports
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/platform_tags.dart';

//local imports
import 'ScanResultsScreen.dart';
import '../utils/navigation_arguments.dart';
import '../nfc/commands.dart';
import '../web3/contractCalls.dart';
import '../widgets/AppBarWithLogo.dart';
import '../widgets/ScanningLoader.dart';

class ScanningScreen extends StatefulWidget {
  const ScanningScreen({super.key, this.connector, this.loginWithMetaMask});

  final WalletConnect? connector;
  final Function? loginWithMetaMask;

  static const routeName = '/scanning';

  @override
  State<ScanningScreen> createState() => _ScanningScreen();
}

//flutter stateless widget
class _ScanningScreen extends State<ScanningScreen> {
  @override
  void initState() {
    super.initState();
    initScanning();
  }

  void initScanning() async {
    print('from initScanning');
    String nftOwner;
    bool chipIsInitialized;

    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      var isoDep = IsoDep.from(tag);
      if (isoDep == null) {
        //TODO: Set some error state
        NfcManager.instance.stopSession();
        return;
      }

      try {
        var selectAppResponse = await isoDep.transceive(data: SELECT_APP);

        Uint8List GET_KEY_INFO = make_get_key_info_command(0x01);
        var responseGetKeyInfo = await isoDep.transceive(data: GET_KEY_INFO);

        //check if first key does not exist yet exist
        if (responseGetKeyInfo[responseGetKeyInfo.length - 2] == 106 &&
            responseGetKeyInfo[responseGetKeyInfo.length - 1] == 136) {
          //key does not exist
          chipIsInitialized = false;
        } else {
          //key exists
          chipIsInitialized = true;
        }

        //get cardID and convert to int (tokenId)
        var tokenId = bytesToInt(selectAppResponse.sublist(1, 11));
        //get owner of nft with cardId == tokenId
        try {
          nftOwner = await getOwner(tokenId);
        } catch (e) {
          print(e);
          chipIsInitialized = false;
          nftOwner = 'Error fetching owner';
        }

        NfcManager.instance.stopSession();

        Navigator.pushNamed(context, ScanResultsScreen.routeName,
            arguments: ScanResultsScreenArguments(nftOwner, chipIsInitialized));
      } catch (e) {
        print("Error transceiving isoDep: $e");
        NfcManager.instance.stopSession();
      }
    });
  }

  void cancelScan() {
    NfcManager.instance.stopSession();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBarWithLogo(
        connectedWallet: widget.connector!.session?.accounts!.isEmpty == true
            ? null
            : widget.connector!.session?.accounts![0].toLowerCase(),
        loginFunction: widget.loginWithMetaMask,
        text: 'Scanning...',
      ),
      body: SafeArea(
          child: Center(
              child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Place your phone close to the chip.'),
          const SizedBox(height: 90),
          const Icon(
            Icons.nfc,
            color: Colors.black,
            size: 96.0,
            semanticLabel: 'Text to announce in accessibility modes',
          ),
          const SizedBox(height: 15),
          const ScanningLoader(),
          const SizedBox(height: 15),
          const Icon(
            Icons.smartphone,
            color: Colors.black,
            size: 96.0,
            semanticLabel: 'Text to announce in accessibility modes',
          ),
          const SizedBox(height: 90),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey, // background
              ),
              onPressed: () => cancelScan(),
              child: const Text('Cancel'))
        ],
      ))),
    );
  }
}
