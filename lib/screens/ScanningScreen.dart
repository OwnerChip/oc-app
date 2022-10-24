import 'package:flutter/material.dart';
import 'dart:typed_data';

//web3 imports
import 'package:web3dart/crypto.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';

//nfc imports
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/platform_tags.dart';

//local imports
import 'MetadataInputScreen.dart';
import 'ChipAlreadyInitializedScreen.dart';
import '../utils/navigation_arguments.dart';
import '../nfc/commands.dart';
import '../web3/web3.services.dart';
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
    dynamic tokenId;

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
        var cardId = bytesToInt(selectAppResponse.sublist(1, 11));
        //get owner of nft with cardId == tokenId
        try {
          nftOwner = await getOwner(cardId);
          tokenId = cardId;
        } catch (e) {
          print(e);
          chipIsInitialized = false;
          tokenId = null;
          nftOwner = 'Error fetching owner';
        }

        NfcManager.instance.stopSession();

        if (chipIsInitialized) {
          Navigator.pushNamed(context, ChipAlreadyInitializedScreen.routeName,
              arguments: ChipAlreadyInitializedScreenArguments(
                widget.connector,
                tokenId,
              ));
        } else {
          //TODO: Navigate to metadata screen
          Navigator.pushNamed(context, MetadataScreen.routeName);
        }
      } catch (e) {
        print("Error transceiving isoDep: $e");
        //TODO: Set some error state and display in UI
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
