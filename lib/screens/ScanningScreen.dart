import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:web3dart/credentials.dart';
import 'dart:typed_data';
import '../utils/localization.helper.dart';
import 'package:web3dart/crypto.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/platform_tags.dart';
import 'UserScanResultsScreen.dart';
import 'MetadataInputScreen.dart';
import 'ChipAlreadyInitializedScreen.dart';
import '../utils/navigation_arguments.dart';
import '../utils/signature.service.dart';
import '../utils/utils.dart';
import '../utils/nfc.commands.dart';
import '../utils/web3.services.dart';
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
        Uint8List GET_KEY_INFO = make_get_key_info_command(0x01);
        Uint8List responseGetKeyInfo =
            await isoDep.transceive(data: GET_KEY_INFO);
        Uint8List chipPubKey = getPublicKeyFromChipResponse(responseGetKeyInfo);
        Uint8List chipEthereumAddress = publicKeyToAddress(chipPubKey);
        String chipEthereumAddressHexString =
            getEthereumAddressHexString(chipEthereumAddress);
        print("$chipEthereumAddressHexString  (Card ID as HexString)");
        BigInt chipTokenId = hexToBigInt(chipEthereumAddress);
        print("$chipTokenId (Card ID as bigInt)");

        //check if first key does not exist yet exist
        if (responseGetKeyInfo[responseGetKeyInfo.length - 2] == 106 &&
            responseGetKeyInfo[responseGetKeyInfo.length - 1] == 136) {
          //key does not exist
          chipIsInitialized = false;
        } else {
          //key exists
          chipIsInitialized = true;
        }

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

        /* TODO: verify chip authenticity via SMART CONTRACT
        // To achieve this, the msg hash needs to be prefixed --> use prepareMsgForSignature()
        try {
          bool result = await verifyTokenSigner(
              chipEthereumAddressHexString, hashedTokenId, signature);
          print(result);
        } catch (e) {
          print("ERROR: $e");
        }
        */

        // get owner of nft with chipEthereumAddress == tokenId
        try {
          EthereumAddress ownerAddress = await getOwner(chipTokenId);
          nftOwner = ownerAddress.toString();
          tokenId = chipTokenId;
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
                  chipTokenId,
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
            Navigator.pushNamed(context, MetadataScreen.routeName,
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
          const Icon(
            Icons.nfc,
            color: Colors.black,
            size: 96.0,
            semanticLabel: 'NFC Icon',
          ),
          const SizedBox(height: 15),
          const ScanningLoader(),
          const SizedBox(height: 15),
          const Icon(
            Icons.smartphone,
            color: Colors.black,
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
