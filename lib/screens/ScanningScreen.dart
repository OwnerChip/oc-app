import 'dart:convert';
import 'package:convert/convert.dart';
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
import '../utils/nfc.commands.dart';
import '../utils/web3.services.dart';
import '../utils/signature.service.dart';
import '../widgets/CustomAppBar.dart';
import '../widgets/ScanningLoader.dart';
import '../widgets/returnSnackBarWidget.dart';

class ScanningScreen extends StatefulWidget {
  const ScanningScreen(
      {super.key,
      required this.connector,
      this.loginWithMetaMask,
      required this.connected});

  final WalletConnect connector;
  final Function? loginWithMetaMask;
  final bool connected;

  static const routeName = '/scanning';

  @override
  State<ScanningScreen> createState() => _ScanningScreen();
}

//flutter stateless widget
class _ScanningScreen extends State<ScanningScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
        Uint8List GET_KEY_INFO = make_get_key_info_command(
            0x01); //make command to get first generated wallet
        var responseGetKeyInfo = await isoDep.transceive(data: GET_KEY_INFO);

        //check if first key does not exist yet exist; [106, 136] is error code for key does not exist in decimal
        if (responseGetKeyInfo[responseGetKeyInfo.length - 2] == 106 &&
            responseGetKeyInfo[responseGetKeyInfo.length - 1] == 136) {
          print('first key does not exist yet');
          //if first generated wallet does not yet exist, generate it on chip
          var responseGenerateKey = await isoDep.transceive(data: GENERATE_KEY);
          //get first key info after generating new key
          responseGetKeyInfo = await isoDep.transceive(data: GET_KEY_INFO);
        }
        //check if response from get key is does NOT have success code 90 00 in hex --> 144 0 in decimal
        else if (!(responseGetKeyInfo[responseGetKeyInfo.length - 2] == 144 &&
            responseGetKeyInfo[responseGetKeyInfo.length - 1] == 00)) {
          throw Exception("Error while generating key");
        }
        print('first key already exists');
        Uint8List chipPubKey = getPublicKeyFromChipResponse(responseGetKeyInfo);
        Uint8List chipEthereumAddress = publicKeyToAddress(chipPubKey);
        String chipEthereumAddressHexString =
            getEthereumAddressHexString(chipEthereumAddress);
        print("$chipEthereumAddressHexString  (Card ID as HexString)");
        BigInt chipTokenId = hexToBigInt(chipEthereumAddress);
        print("$chipTokenId (Card ID as bigInt)");

        // get SIGNATURE from NFC chip
        final Uint8List hashedTokenId = keccakUtf8(chipTokenId.toString());
        final Uint8List getSigCmd = make_signature_command(0x01, hashedTokenId);
        final Uint8List responseGetSignature =
            await isoDep.transceive(data: getSigCmd);

        // TEST: extract and implicitly verify signature
        final MsgSignature signature =
            extractSignature(chipTokenId, responseGetSignature);

        // only if true, is the tokenId corresponding to the chip!
        bool verificationResult =
            verifySignature(chipTokenId, signature.r, signature.s);
        if (!verificationResult) {
          throw ("ERROR: INVALID CHIP! It is not related to tokenId: $chipTokenId");
        }

        // verify chip authenticity via SMART CONTRACT
        try {
          bool result = await verifyTokenSigner(
              chipEthereumAddressHexString, hashedTokenId, signature);
          print("SMART CONTRACT VERIFICATION RESULT: $result");
        } catch (e) {
          print("ERROR: $e");
        }

        // get owner of nft with cardId == tokenId
        try {
          EthereumAddress ownerAddress = await getOwner(chipTokenId);
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
                  nftOwner,
                  chipIsInitialized,
                  chipEthereumAddress,
                  chipEthereumAddressHexString));
        } else {
          //chip already initialized: navigate to ChipAlreadyInitializedScreen
          if (chipIsInitialized) {
            // ignore: use_build_context_synchronously
            Navigator.pushReplacementNamed(
                context, ChipAlreadyInitializedScreen.routeName,
                arguments: ChipAlreadyInitializedScreenArguments(
                    chipEthereumAddress,
                    chipEthereumAddressHexString,
                    hashedTokenId,
                    signature));
          } else {
            //chip not initialized: navigate to MetadataScreen
            // ignore: use_build_context_synchronously
            Navigator.pushReplacementNamed(context, MetadataScreen.routeName,
                arguments: ChipInitializedArguments(chipEthereumAddress,
                    chipEthereumAddressHexString, hashedTokenId, signature));
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
      appBar: CustomAppBar(
        connectedWalletAddress:
            widget.connector?.session?.accounts!.isEmpty == true
                ? null
                : widget.connector?.session?.accounts![0].toLowerCase(),
        loginFunction: widget.loginWithMetaMask,
        text: navArgs.scanningTitle,
        connector: widget.connector,
        isConnected: widget.connected,
        showBackButton: false,
      ),
      body: SafeArea(
          child: Center(
              child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            context.loc.scanHint,
            overflow: TextOverflow.fade,
            //center text
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 90),
          Icon(
            Icons.nfc,
            color: Theme.of(context).primaryColor,
            size: 96.0,
            semanticLabel: 'NFC Icon',
          ),
          const SizedBox(height: 15),
          const ScanningLoader(),
          const SizedBox(height: 15),
          Icon(
            Icons.smartphone,
            color: Theme.of(context).primaryColor,
            size: 96.0,
            semanticLabel: 'Smartphone Icon',
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
