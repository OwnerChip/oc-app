import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:web3dart/crypto.dart';
import 'dart:io';
import '../utils/localization.helper.dart';

//web3 imports
import 'package:walletconnect_dart/walletconnect_dart.dart';

//local imports
import '../widgets/CustomAppBar.dart';
import '../utils/navigation_arguments.dart';
import '../utils/ipfs.services.dart';
import '../utils/web3.services.dart';
import '../utils/url_generator.service.dart';
import '../utils/utils.dart';
import 'HomeScreen.dart';
import '../widgets/returnSnackBarWidget.dart';
import '../widgets/CustomCard.dart';
import '../widgets/ScreenBodyLayout.dart';
import '../widgets/CustomImage.dart';
import '../widgets/SmallTextContainer.dart';
import '../widgets/CustomRoundedButton.dart';

class NFTDetailsScreen extends StatefulWidget {
  const NFTDetailsScreen(
      {super.key,
      required this.connector,
      this.loginWithMetaMask,
      required this.connected});
  final WalletConnect connector;
  final Function? loginWithMetaMask;
  final bool connected;

  static const routeName = '/nft-details';

  @override
  State<NFTDetailsScreen> createState() => _NFTDetailsScreen();
}

class _NFTDetailsScreen extends State<NFTDetailsScreen> {
  String imagePath = "";
  String imageUri = "";
  Map<String, dynamic> metadata = {};
  bool loadingImage = true;

  // get the metadata.json file from IPFS associated with a token
  Future<Map<String, dynamic>> _fetchMetadata(BigInt tokenId) async {
    Map<String, dynamic> result = {};
    try {
      // get IPFS CID
      String tokenUri = await getTokenUri(tokenId);

      // fetch metadata json
      String jsonCid = getCidFromIpfsLink(tokenUri);
      final Directory directory = Directory.systemTemp;
      File jsonFile = File("${directory.path}/$jsonCid.metadata.json");
      await downloadMetadataFileFromIPFS(jsonCid, jsonFile.path, false);

      // read metadata json
      final String res = await jsonFile.readAsString();
      metadata = Map<String, dynamic>.from(json.decode(res));
      result = metadata;
    } catch (e) {
      print("error $e");
      // throw Exception("Error fetching metadata: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        returnSnackBarWidget(context.loc.errorHeadingSnackBar,
            context.loc.loadingNFTDataError, 'error'),
      );
    }
    return result;
  }

  // get the path of the associated image locally if available OR from IPFS if not
  Future<void> _fetchImage(
      String imgPath, Future<Map<String, dynamic>> meta) async {
    try {
      setState(() {
        loadingImage = true;
      });
      if (imgPath != "") {
        metadata = await meta;
        imagePath = imgPath;
      } else {
        Map<String, dynamic> metaSync = await meta;
        if (metaSync.containsKey("image") && metaSync['image']!.isNotEmpty) {
          String imageCid = getCidFromIpfsLink(metaSync['image']!);
          Map<String, String> result =
              await downloadImageFileFromIPFS(imageCid);
          imagePath = result['imagePath']!;
          imageUri = result['imageUri']!;
        }
      }

      // updateScreen
      setState(() {
        metadata;
        imagePath;
        loadingImage = false;
      });
    } catch (e) {
      print("error fetching image: $e");
      setState(() {
        loadingImage = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        returnSnackBarWidget(context.loc.errorHeadingSnackBar,
            context.loc.loadingNFTDataError, 'error'),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      final NFTDetailsScreenArguments navArgs = ModalRoute.of(context)!
          .settings
          .arguments as NFTDetailsScreenArguments;
      Future<Map<String, dynamic>> meta =
          _fetchMetadata(bytesToUnsignedInt(navArgs.tokenId));
      String imgPath = (navArgs.localImagePath) ?? "";
      _fetchImage(imgPath, meta);
    } catch (e) {
      //snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        returnSnackBarWidget(context.loc.errorHeadingSnackBar,
            context.loc.loadingNFTDataError, 'error'),
      );
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final NFTDetailsScreenArguments navArgs =
        ModalRoute.of(context)!.settings.arguments as NFTDetailsScreenArguments;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        loginFunction: widget.loginWithMetaMask,
        text: context.loc.nftDetails,
        connectedWalletAddress:
            widget.connector.session.accounts.isEmpty == true
                ? null
                : widget.connector.session.accounts[0].toLowerCase(),
        connector: widget.connector,
        isConnected: widget.connected,
      ),
      body: ScreenBodyLayout(children: [
        CustomCard(
          children: [
            CustomImage(
              loading: loadingImage,
              imagePath: imagePath,
              tokenId: bytesToUnsignedInt(navArgs.tokenId),
            ),
            //spacing
            SizedBox(height: 20),
            Row(
              children: [
                Text(
                    metadata['name'] ??
                        'Loading...', //TODO: extract string to localization
                    style: TextStyle(
                        fontSize: 20,
                        color: Theme.of(context).primaryColorLight,
                        fontWeight: FontWeight
                            .bold)), //TODO: Move font styles to separate file e.g. as "Heading style 1"
              ],
            ),
            Divider(
              color: Theme.of(context).primaryColor,
              height: 20,
              thickness: 1,
              indent: 0,
              endIndent: 0,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                  metadata['description'] ??
                      'Loading...', //TODO: extract string to localization
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
            ),
            //spacing
            SizedBox(height: 20),
            CustomRoundedButton(
              text: context.loc.showOnExplorer,
              onPressed: () => {
                launchUrl(generateBlockchainExplorerTokenDetailsUrl(
                    bytesToUnsignedInt(navArgs.tokenId).toString()))
              },
            ),
            const SizedBox(height: 15),
            CustomRoundedButton(
              text: context.loc.showOnOpenSea,
              onPressed: () => {
                launchUrl(generateOpenSeaTokenDetailsUrl(
                    bytesToUnsignedInt(navArgs.tokenId).toString()))
              },
            ),
          ],
        )
      ]),
    );
  }
}
