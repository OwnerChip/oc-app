import 'package:flutter/material.dart';
import 'package:web3dart/credentials.dart';
import 'dart:typed_data';
import '../utils/localization.helper.dart';

//web3 imports
import 'package:web3dart/crypto.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';

//nfc imports
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/platform_tags.dart';

//local imports
import 'UserScanResultsScreen.dart';
import 'MetadataInputScreen.dart';
import 'ChipAlreadyInitializedScreen.dart';
import '../utils/navigation_arguments.dart';
import '../utils/utils.dart';
import '../nfc/commands.dart';
import '../web3/web3.services.dart';
import '../widgets/AppBarWithLogo.dart';
import '../widgets/ScanningLoader.dart';
import '../widgets/returnSnackBarWidget.dart';

class ScanningScreen extends StatefulWidget {
  const ScanningScreen(
      {super.key, required this.connector, this.loginWithMetaMask});

  final WalletConnect connector;
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
    String nftOwner;
    bool chipIsInitialized = false;
    dynamic tokenId;

    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      try {
        //check if there is internet connections
        if (!await checkInternetConnection()) {
          throw Exception("No internet connection");
        }

        final navArgs = ModalRoute.of(context)!.settings.arguments
            as ScanningScreenArguments;

        var isoDep = IsoDep.from(tag);
        //check if isodep is available and exit if not
        if (isoDep == null) {
          NfcManager.instance.stopSession();
          throw Exception('Tag is not ISO-DEP.');
        }
        var selectAppResponse = await isoDep.transceive(data: SELECT_APP);
        Uint8List GET_KEY_INFO = make_get_key_info_command(0x01);
        var responseGetKeyInfo = await isoDep.transceive(data: GET_KEY_INFO);

        //check if first key does not exist yet exist
        if (responseGetKeyInfo[responseGetKeyInfo.length - 2] == 106 &&
            responseGetKeyInfo[responseGetKeyInfo.length - 1] == 136) {
          //if first generated wallet does not yet exist, generate it on chip
          var responseGenerateKey = await isoDep.transceive(data: GENERATE_KEY);
          //get new key info after generating new key
          responseGetKeyInfo = await isoDep.transceive(data: GET_KEY_INFO);
          print(responseGetKeyInfo);
        }
        //check if response from get key is does NOT have success code 90 00 in hex --> 144 0 in decimal
        else if (!(responseGetKeyInfo[responseGetKeyInfo.length - 2] == 144 &&
            responseGetKeyInfo[responseGetKeyInfo.length - 1] == 00)) {
          throw Exception("Error while generating key");
        }
        var uin8key = responseGetKeyInfo.sublist(9, 73); //get 64 bit public key
        var uint8Address = publicKeyToAddress(uin8key);
        var chipWalletAddress = makeHexFromUint8List(uint8Address);

        //get cardID and convert to int (tokenId)
        var cardId = selectAppResponse.sublist(1, 11);
        //get owner of nft with cardId == tokenId
        try {
          tokenId = bytesToInt(cardId);
          EthereumAddress ownerAddress = await getOwner(tokenId);
          nftOwner = ownerAddress.toString();

          //chip is initialized if this didnt catch!
          chipIsInitialized = true;
        } catch (e) {
          //NFT with this token ID does not have an owner/does not exist
          print(e);
          chipIsInitialized = false;
          tokenId = null;
          nftOwner = context.loc.ownerError;
        }

        NfcManager.instance.stopSession();
        //navigate to UserScanResultsScreen
        if (navArgs.nextRoute == UserScanResultsScreen.routeName) {
          // ignore: use_build_context_synchronously
          Navigator.pushReplacementNamed(
              context, UserScanResultsScreen.routeName,
              arguments: UserScanResultsScreenArguments(
                  nftOwner, chipIsInitialized, tokenId, chipWalletAddress));
        } else {
          //chip already initialized: navigate to ChipAlreadyInitializedScreen
          if (chipIsInitialized) {
            // ignore: use_build_context_synchronously
            Navigator.pushReplacementNamed(
                context, ChipAlreadyInitializedScreen.routeName,
                arguments: ChipAlreadyInitializedScreenArguments(
                    cardId, chipWalletAddress));
          } else {
            //chip not initialized: navigate to MetadataScreen
            // ignore: use_build_context_synchronously
            Navigator.pushReplacementNamed(context, MetadataScreen.routeName,
                arguments: ChipAlreadyInitializedScreenArguments(
                    cardId, chipWalletAddress));
          }
        }
      } catch (e) {
        //error reading chip
        print(context.loc.isoDepError + ": $e");
        NfcManager.instance.stopSession();
        ScaffoldMessenger.of(context).showSnackBar(
          returnSnackBarWidget(
              context.loc.errorHeadingSnackBar, context.loc.nfcError, 'error'),
        );
        //delay for 1 second
        await Future.delayed(Duration(seconds: 1));
        //navigate back to previous screen
        Navigator.pop(context);
      }
    });
  }

  void cancelScan() {
    NfcManager.instance.stopSession();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final navArgs =
        ModalRoute.of(context)!.settings.arguments as ScanningScreenArguments;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBarWithLogo(
        connectedWallet: widget.connector?.session?.accounts!.isEmpty == true
            ? null
            : widget.connector?.session?.accounts![0].toLowerCase(),
        loginFunction: widget.loginWithMetaMask,
        text: navArgs.scanningTitle,
        connector: widget.connector,
      ),
      body: SafeArea(
          child: Center(
              child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            context.loc.scanHint,
            overflow: TextOverflow.fade,
          ),
          SizedBox(height: 90),
          Icon(
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
              child: Text(context.loc.cancel))
        ],
      ))),
    );
  }
}
