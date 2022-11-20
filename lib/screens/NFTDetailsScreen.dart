import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'dart:io';
import '../utils/localization.helper.dart';

//web3 imports
import 'package:walletconnect_dart/walletconnect_dart.dart';

//local imports
import '../widgets/AppBarWithLogo.dart';
import '../utils/navigation_arguments.dart';
import '../utils/ipfs.services.dart';
import '../utils/web3.services.dart';
import '../utils/url_generator.service.dart';
import '../utils/utils.dart';
import 'HomeScreen.dart';
import '../widgets/returnSnackBarWidget.dart';

class NFTDetailsScreen extends StatefulWidget {
  const NFTDetailsScreen(
      {super.key, required this.connector, this.loginWithMetaMask});
  final WalletConnect connector;
  final Function? loginWithMetaMask;

  static const routeName = '/nft-details';

  @override
  State<NFTDetailsScreen> createState() => _NFTDetailsScreen();
}

class _NFTDetailsScreen extends State<NFTDetailsScreen> {
  String statusText = "";
  String imagePath = "";
  String imageUri = "";
  Map<String, dynamic> metadata = {};

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
      statusText = context.loc.itemData;
      setState(() {
        metadata;
        imagePath;
        statusText = "";
      });
    } catch (e) {
      print("error fetching image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        returnSnackBarWidget(context.loc.errorHeadingSnackBar,
            context.loc.loadingNFTDataError, 'error'),
      );
    }
  }

  Future<void> _addNftToMetamask(String tokenId) async {
    try {
      await launchUrlString('wc:', mode: LaunchMode.externalApplication);
      // TODO: nothing happens yet ?!
      await widget.connector.sendCustomRequest(
          method: 'wallet_watchAsset',
          params: makeWatchAssetParams(imageUri),
          id: makeRandomInt());
    } catch (error) {
      print(error);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      final NFTDetailsScreenArguments navArgs = ModalRoute.of(context)!
          .settings
          .arguments as NFTDetailsScreenArguments;
      Future<Map<String, dynamic>> meta = _fetchMetadata(navArgs.tokenId!);
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
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final NFTDetailsScreenArguments navArgs =
        ModalRoute.of(context)!.settings.arguments as NFTDetailsScreenArguments;

    statusText = "${context.loc.loadingData}";

    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBarWithLogo(
          loginFunction: widget.loginWithMetaMask,
          text: context.loc.nftDetails,
          connectedWallet: widget.connector.session.accounts.isEmpty == true
              ? null
              : widget.connector.session.accounts[0].toLowerCase(),
          connector: widget.connector,
        ),
        body: SafeArea(
          child: Center(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Text('Token ID: ${navArgs.tokenId}'),
                  // IMAGE
                  if (imagePath != "")
                    Image.file(
                      File(imagePath),
                      height: 270,
                      // width: 300,
                    ),
                  if (imagePath == "") const SizedBox(height: 50),
                  if (imagePath == "")
                    Text(statusText,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  // METADATA
                  if (metadata['name'] != null)
                    Text(/*context.loc.itemName + */ '${metadata['name']}',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  if (metadata['description'] != null)
                    Text(
                        /*context.loc.itemDescription +
                              */
                        '${metadata['description']}',
                        style: TextStyle(fontSize: 20)),
                  const SizedBox(height: 50),
                  SizedBox(
                    width: 200,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                      onPressed: () => {
                        launchUrl(generateBlockchainExplorerTokenDetailsUrl(
                            navArgs.tokenId.toString()))
                      },
                      child: Text(context.loc.showOnExplorer),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: 200,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                      onPressed: () => {
                        launchUrl(generateOpenSeaTokenDetailsUrl(
                            navArgs.tokenId.toString()))
                      },
                      child: Text(context.loc.showOnOpenSea),
                    ),
                  ),
                  /*const SizedBox(height: 15),
                    SizedBox(
                      width: 200,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () =>
                            {_addNftToMetamask(navArgs.tokenId.toString())},
                        child: Text(context.loc.showNftInWallet),
                      ),
                    ),*/
                  const SizedBox(height: 15),
                  SizedBox(
                      width: 200,
                      height: 50,
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey, // background
                          ),
                          onPressed: () => {
                                Navigator.pushReplacementNamed(
                                    context, HomeScreen.routeName)
                              },
                          child: Text(context.loc.home))),
                ]),
          ),
        ));
  }
}
