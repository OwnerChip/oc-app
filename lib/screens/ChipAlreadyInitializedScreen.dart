import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ownerchip_whitelabel/themes/fontSpecs_ownerchip.dart';
import 'package:ownerchip_whitelabel/widgets/CustomCard.dart';
import 'package:ownerchip_whitelabel/widgets/CustomRoundedButton.dart';
import 'package:ownerchip_whitelabel/widgets/CustomPopups.dart';
import 'package:ownerchip_whitelabel/widgets/LoadingOverlay.dart';
import 'package:ownerchip_whitelabel/widgets/ScreenBodyLayout.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:convert/convert.dart';
import '../utils/localization.helper.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_svg/flutter_svg.dart';

//web3 imports
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web3dart/crypto.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import '../utils/ipfs.services.dart';

// import local files
import '../widgets/CustomAppBar.dart';
import '../utils/navigation_arguments.dart';
import '../utils/url_generator.service.dart';
import 'HomeScreen.dart';
import '../utils/utils.dart';
import '../utils/web3.services.dart';
import '../widgets/returnSnackBarWidget.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs_ownerchip.dart';

class ChipAlreadyInitializedScreen extends StatefulWidget {
  const ChipAlreadyInitializedScreen(
      {super.key,
      required this.connector,
      this.loginWithMetaMask,
      required this.connected});
  final WalletConnect connector;
  final Function? loginWithMetaMask;
  final bool connected;

  static const routeName = '/scan-already-initialized';

  @override
  State<StatefulWidget> createState() => _ChipAlreadyInitializedState();
}

class _ChipAlreadyInitializedState extends State<ChipAlreadyInitializedScreen> {
  bool isLoading = false;
  bool isRotating = true;
  String loadingSvgPath =
      '${dotenv.get('IMAGE_ASSETS_BASE_URL')}/chip_dark_blue.svg';
  String loadingText = '';

  Future<void> burnToken(
      BigInt tokenId, Uint8List tokenIdHash, MsgSignature signature) async {
    try {
      // to burn the related IPFS files here, we first need to fetch metadata.json read it and return image file CID
      // String tokenUri = await getTokenUri(tokenId);
      // String metadataFileCid = getCidFromIpfsLink(tokenUri);
      // String imageCid = "";
      // final Directory directory = Directory.systemTemp;
      // File jsonFile = File("${directory.path}/$metadataFileCid.metadata.json");
      // await downloadMetadataFileFromIPFS(metadataFileCid, jsonFile.path, false);
      // final String res = await jsonFile.readAsString();
      // Map<String, dynamic> metadata =
      //     Map<String, dynamic>.from(json.decode(res));
      // if (metadata.containsKey("image") && metadata['image']!.isNotEmpty) {
      //   imageCid = getCidFromIpfsLink(metadata['image']!);
      // }

      var burnParams = await makeSignedBurnParams(
          widget.connector.session.accounts[0], tokenIdHash, signature);

      //if wc bridge is not connected, then reconnect
      if (!widget.connector.bridgeConnected) {
        widget.connector.reconnect();
      }

      await launchUrlString('wc:', mode: LaunchMode.externalApplication);
      var txnHash = await widget.connector.sendCustomRequest(
          method: 'eth_sendTransaction',
          params: burnParams,
          id: makeRandomInt());

      setState(() {
        isLoading = true;
        loadingText = context.loc.burning;
      });

      var txnReceipt = await getTxnReceipt(txnHash);
      if (txnReceipt?.status == true) {
        //this means burn succeeded

        // try deleting IPFS files
        // try {
        //   bool success1 = await upinFileFromIPFS(metadataFileCid);
        //   if (!success1) {
        //     throw ("Could not delete image file $metadataFileCid from IPFS");
        //   }
        //   if (imageCid != "") {
        //     bool success2 = await upinFileFromIPFS(imageCid);
        //     if (!success2) {
        //       throw ("Could not delete image file $imageCid from IPFS");
        //     }
        //   }
        // } catch (e) {
        //   print("ERROR deleting files from IPFS: $e");
        // }

        setState(() {
          isRotating = false;
          loadingSvgPath = "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/burn.svg";
          loadingText = context.loc.burnedSuccess;
        });

        //delay 2 second
        await Future.delayed(Duration(seconds: 2));

        // setState(() {
        //   isLoading = false;
        // });

        //navigate to login screen
        // ignore: use_build_context_synchronously
        Navigator.pushReplacementNamed(context, HomeScreen.routeName);
      } else {
        throw Exception(context.loc.burnedError);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        returnSnackBarWidget(
            context.loc.errorHeadingSnackBar, context.loc.burnedError, 'error'),
      );
      print("Error: $e");
    }
  }

  Future<void> burnAndMintToken(Uint8List tokenId) async {}

  @override
  Widget build(BuildContext context) {
    final navArgs = ModalRoute.of(context)!.settings.arguments
        as ChipAlreadyInitializedScreenArguments;
    final Uint8List tokenId = navArgs.tokenId;
    final Uint8List tokenIdHash = keccakUtf8(hexToBigInt(tokenId).toString());
    final MsgSignature signature = navArgs.signature;

    return LoadingOverlay(
      isLoading: isLoading,
      loadingText: loadingText,
      rotateIcon: isRotating,
      svgPath: loadingSvgPath,
      child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: CustomAppBar(
            loginFunction: () => {},
            text: context.loc.initializeChip,
            connectedWalletAddress:
                widget.connector.session.accounts.isEmpty == true
                    ? null
                    : widget.connector.session.accounts[0].toLowerCase(),
            connector: widget.connector,
            isConnected: widget.connected,
          ),
          body: ScreenBodyLayout(
            withScrollView: false,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomCard(
                  color: CustomColors(dotenv.get('APP_ID')).cardColor,
                  width: 300,
                  children: [
                    //orange round ember warning icon
                    Icon(Icons.warning_amber_rounded,
                        color: CustomColors(dotenv.get('APP_ID')).warningColor,
                        size:
                            CustomFonts.AdminWarningHeadlineFontSize), //spacing
                    const SizedBox(
                      height: 20,
                    ),
                    Text(
                      context.loc.warning,
                      style: TextStyle(
                          color:
                              CustomColors(dotenv.get('APP_ID')).warningColor,
                          fontSize: CustomFonts.AdminWarningSubtextFontSize,
                          fontWeight:
                              CustomFonts.AdminWarningSubtextFontWeight),
                    ),
                    //spacing
                    const SizedBox(height: 10),
                    Text(
                      textAlign: TextAlign.center,
                      context.loc.alreadyLinked,
                      style: Theme.of(context).textTheme.headline5!,
                    ),

                    //spacing
                    const SizedBox(
                      height: 50,
                    ),

                    CustomRoundedButton(
                      width: 250,
                      text: context.loc.burnToken,
                      onPressed: () => {
                        burnToken(
                            hexToBigInt(tokenId), navArgs.hashedMsg, signature)
                      },
                    ),

                    const SizedBox(
                      height: 40,
                    ),
                    CustomRoundedButton(
                        width: 250,
                        text: context.loc.showOnExplorer,
                        onPressed: () => {
                              launchUrl(
                                  generateBlockchainExplorerTokenDetailsUrl(
                                      tokenId.toString()))
                            }),
                    //spacing
                    const SizedBox(
                      height: 8,
                    ),
                    CustomRoundedButton(
                      width: 250,
                      text: context.loc.showOnOpenSea,
                      onPressed: () => {
                        launchUrl(
                            generateOpenSeaTokenDetailsUrl(
                                bytesToUnsignedInt(tokenId).toString()),
                            mode: LaunchMode.externalApplication)
                      },
                    ),
                    const SizedBox(
                      height: 40,
                    ),
                  ]),
              //spacing
              const SizedBox(
                height: 20,
              ),
              CustomRoundedButton(
                width: 250,
                text: context.loc.cancel,
                onPressed: () => {
                  Navigator.pushReplacementNamed(context, HomeScreen.routeName)
                },
              ),
            ],
          )),
    );
  }
}
