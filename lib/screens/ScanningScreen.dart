import 'dart:convert';
import 'dart:io' show Platform;
import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:web3dart/credentials.dart';
import 'dart:typed_data';
import '../utils/localization.helper.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';

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
import '../widgets/CustomRoundedButton.dart';
import '../widgets/ScreenBodyLayout.dart';

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
    int randomNumber = makeRandomInt();

    try {
      //check if there is internet connections
      if (!await checkInternetConnection()) {
        throw Exception("No internet connection");
      }
    } catch (e) {
      //error reading chip
      print(context.loc.isoDepError + ": $e");
      NfcManager.instance.stopSession();
      ScaffoldMessenger.of(context).showSnackBar(
        returnSnackBarWidget(context.loc.errorHeadingSnackBar,
            context.loc.errorNoInternetConnection, 'error'),
      );
      //delay for 1 second
      await Future.delayed(Duration(seconds: 1));
      //navigate back to previous screen
      Navigator.pop(context);
    }
    final navArgs =
        ModalRoute.of(context)!.settings.arguments as ScanningScreenArguments;

    //start NFC scan
    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      try {
        var nfc = NFCPlatform(tag);

        //check if iso7816 or isodep is available and exit if not
        if (nfc == null) {
          NfcManager.instance.stopSession();
          throw Exception('Tag is not ISO-DEP.');
        }
        var selectAppResponse = await nfc.sendCommand(SELECT_APP);
        Uint8List GET_KEY_INFO = make_get_key_info_command(
            0x01); //make command to get first generated wallet
        var responseGetKeyInfo = await nfc.sendCommand(GET_KEY_INFO);

        Uint8List getKeyInfoData = responseGetKeyInfo[0];
        int getKeyInfoSw1 = responseGetKeyInfo[1];
        int getKeyIinfoSw2 = responseGetKeyInfo[2];
        //check if first key does not exist yet exist; [106, 136] is error code for key does not exist in decimal
        if (getKeyInfoSw1 == 106 && getKeyIinfoSw2 == 136) {
          //if first generated wallet does not yet exist, generate it on chip
          var responseGenerateKey = await nfc.sendCommand(GENERATE_KEY);
          //get first key info after generating new key
          responseGetKeyInfo = await nfc.sendCommand(GET_KEY_INFO);
          getKeyInfoData = responseGetKeyInfo[0];
          getKeyInfoSw1 = responseGetKeyInfo[1];
          getKeyIinfoSw2 = responseGetKeyInfo[2];
        }
        //check if response from get key is does NOT have success code 90 00 in hex --> 144 0 in decimal
        else if (!(getKeyInfoSw1 == 144 && getKeyIinfoSw2 == 00)) {
          throw Exception("Error while generating key");
        }
        Uint8List chipPubKey = getPublicKeyFromChipResponse(getKeyInfoData);
        Uint8List chipEthereumAddress = publicKeyToAddress(chipPubKey);
        String chipEthereumAddressHexString =
            getEthereumAddressHexString(chipEthereumAddress);
        BigInt chipTokenId = hexToBigInt(chipEthereumAddress);

        // get SIGNATURE from NFC chip
        final Uint8List hashedMsg = keccakUtf8(randomNumber.toString());
        final Uint8List getSigCmd = make_signature_command(0x01, hashedMsg);
        final List responseGetSignature = await nfc.sendCommand(getSigCmd);
        final Uint8List chipSignatureData = responseGetSignature[0];
        final int chipSignatureSw1 = responseGetSignature[1];
        final int chipSignatureSw2 = responseGetSignature[2];

        //vibrate phone
        HapticFeedback.vibrate();
        await Future.delayed(Duration(milliseconds: 50));
        HapticFeedback.vibrate();
        await Future.delayed(Duration(milliseconds: 50));
        HapticFeedback.vibrate();

        // TEST: extract and implicitly verify signature
        final MsgSignature signature =
            extractSignature(chipTokenId, hashedMsg, chipSignatureData);

        // only if true, is the tokenId corresponding to the chip!
        bool verificationResult =
            verifySignature(chipTokenId, hashedMsg, signature.r, signature.s);
        if (!verificationResult) {
          throw ("ERROR: INVALID CHIP! It is not related to tokenId: $chipTokenId");
        }

        // verify chip authenticity via SMART CONTRACT
        try {
          bool result = await verifyTokenSigner(
              chipEthereumAddressHexString, hashedMsg, signature);
        } catch (e) {
          print("ERROR: $e");
          throw ("NFC Chip not valid, signature verification failed");
        }

        // get owner of nft with cardId == tokenId
        try {
          EthereumAddress ownerAddress = await getOwner(chipTokenId);
          nftOwner = ownerAddress.toString();

          //chip is initialized if this didnt catch!
          chipIsInitialized = true;
        } catch (e) {
          //NFT with this token ID does not have an owner/does not exist
          chipIsInitialized = false;
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
                    hashedMsg,
                    signature));
          } else {
            //chip not initialized: navigate to MetadataScreen
            // ignore: use_build_context_synchronously
            Navigator.pushReplacementNamed(context, MetadataScreen.routeName,
                arguments: ChipInitializedArguments(chipEthereumAddress,
                    chipEthereumAddressHexString, hashedMsg, signature));
          }
        }
      } catch (e) {
        //error reading chip
        NfcManager.instance.stopSession();
        ScaffoldMessenger.of(context).showSnackBar(
          returnSnackBarWidget(
              context.loc.errorHeadingSnackBar, context.loc.nfcError, 'error'),
        );
        //delay for 1 second
        await Future.delayed(Duration(seconds: 1));
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
              widget.connector.session.accounts.isEmpty == true
                  ? null
                  : widget.connector.session.accounts[0].toLowerCase(),
          loginFunction: widget.loginWithMetaMask,
          connector: widget.connector,
          isConnected: widget.connected,
          showBackButton: false,
        ),
        body: ScreenBodyLayout(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          withScrollView: false,
          children: [
            (navArgs.nextRoute == MetadataScreen.routeName)
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.loc.initializeChip,
                          style: Theme.of(context).textTheme.headline2),
                      RichText(
                        text: TextSpan(
                            text: 'Step 1/',
                            style: Theme.of(context)
                                .textTheme
                                .headline6!
                                .copyWith(fontSize: 18),
                            children: [
                              TextSpan(
                                  text: '2',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headline5!
                                      .copyWith(fontSize: 18))
                            ]),
                      )
                    ],
                  )
                : Text(context.loc.scanning,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headline2),
            Column(
              children: [
                SvgPicture.asset(
                  'assets/images/chip_light_blue.svg',
                  width: 70.0,
                ),
                const SizedBox(height: 20),
                const ScanningLoader(),
                const SizedBox(height: 20),
                SvgPicture.asset(
                  'assets/images/phone.svg',
                  width: 70.0,
                ),
                const SizedBox(height: 30),
                Text(context.loc.scanHint,
                    overflow: TextOverflow.fade,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyText1!
                    // .copyWith(fontWeight: FontWeight.w400),
                    ),
              ],
            ),
            CustomRoundedButton(
              text: context.loc.cancel,
              onPressed: () => cancelScan(),
            )
          ],
        ));
  }
}
