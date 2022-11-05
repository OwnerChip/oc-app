import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:typed_data';
import 'dart:io';
import '../utils/localization.helper.dart';

//web3 imports
import 'package:web3dart/crypto.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';

//local imports
import '../widgets/AppBarWithLogo.dart';
import '../utils/navigation_arguments.dart';
import '../ipfs/ipfs.services.dart';
import '../web3/web3.services.dart';
import '../utils/url_generator.service.dart';

class NFTDetailsScreen extends StatefulWidget {
  const NFTDetailsScreen({super.key, this.connector, this.loginWithMetaMask});
  final WalletConnect? connector;
  final Function? loginWithMetaMask;

  static const routeName = '/nft-details';

  @override
  State<NFTDetailsScreen> createState() => _NFTDetailsScreen();
}

class _NFTDetailsScreen extends State<NFTDetailsScreen> {
  String statusText = "";
  String imagePath = "";
  Map<String, String> metadata = {};

  Future<void> _fetchResults(tokenId) async {
    try {
      // get IPFS CID
      String tokenUri = await getTokenUri(tokenId);

      // fetch metadata json
      String jsonCid = getCidFromIpfsLink(tokenUri);
      final Directory directory = Directory.systemTemp;
      File jsonFile = File("${directory.path}/${jsonCid}.metadata.json");
      await downloadFileFromIPFS(jsonCid, jsonFile.path);

      // read metadata json
      final String res = await jsonFile.readAsString();
      metadata = new Map<String, String>.from(json.decode(res));

      // fetch image if set in metadata
      if (metadata.containsKey("image") && metadata['image']!.isNotEmpty) {
        String imageCid = getCidFromIpfsLink(metadata['image']!);
        imagePath = await downloadImageFileFromIPFS(imageCid);

        // updateScreen
        statusText = context.loc.itemData;
        setState(() {
          imagePath;
          statusText;
        });
      }
    } catch (e) {
      print("error $e");
    }
  }

  @override
  void didChangeDependencies() {
    final NFTDetailsScreenArguments navArgs =
        ModalRoute.of(context)!.settings.arguments as NFTDetailsScreenArguments;
    _fetchResults(navArgs.tokenId);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final NFTDetailsScreenArguments navArgs =
        ModalRoute.of(context)!.settings.arguments as NFTDetailsScreenArguments;

    setState(() {
      statusText = context.loc.loadingData + " ...";
    });

    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBarWithLogo(
          loginFunction: widget.loginWithMetaMask,
          text: context.loc.nftDetails,
          connectedWallet: widget.connector?.session?.accounts!.isEmpty == true
              ? null
              : widget.connector?.session?.accounts![0].toLowerCase(),
        ),
        body: SafeArea(
            child: Row(children: [
          Expanded(
            flex: 8,
            child: Center(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Text('Token ID: ${navArgs.tokenId}'),
                    if (imagePath != "")
                      Image.file(
                        File(imagePath),
                        height: 200,
                        width: 200,
                      ),
                    if (imagePath == "") const SizedBox(height: 50),
                    Text(statusText,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    if (metadata['title'] != null)
                      Text(context.loc.itemName + ': ${metadata['title']}',
                          style: TextStyle(fontSize: 20)),
                    SizedBox(height: 20),
                    if (metadata['description'] != null)
                      Text(
                          context.loc.itemDescription +
                              ': ${metadata['description']}',
                          style: TextStyle(fontSize: 20)),
                    const SizedBox(height: 120),
                    SizedBox(
                      width: 200,
                      height: 50,
                      child: ElevatedButton(
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
                              backgroundColor: Colors.grey, // background
                            ),
                            onPressed: () => {
                                  Navigator.pushReplacementNamed(
                                      context, '/login')
                                },
                            child: Text(context.loc.home))),
                  ]),
            ),
          )
        ])));
  }
}
