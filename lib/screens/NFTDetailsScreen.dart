import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:io';

//web3 imports
import 'package:web3dart/crypto.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';

//local imports
import '../widgets/AppBarWithLogo.dart';
import '../utils/navigation_arguments.dart';
import '../ipfs/ipfs.services.dart';
import '../web3/web3.services.dart';

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

  Future<void> _fetchResults() async {
    final NFTDetailsScreenArguments navArgs =
        ModalRoute.of(context)!.settings.arguments as NFTDetailsScreenArguments;
    final BigInt tokenId = navArgs.tokenId;

    try {
      // get IPFS CID
      String tokenUri = await getTokenUri(tokenId);

      // fetch metadata json
      final Directory directory = Directory.systemTemp;
      String tempJsonPath = "$directory.path/$tokenUri.metadata.json";
      String jsonCid = getCidFromIpfsLink(tokenUri);
      downloadFileFromIPFS(jsonCid, tempJsonPath);

      // read metadata json
      final File jsonFile = File(tempJsonPath);
      final String res = await jsonFile.readAsString();
      metadata = await jsonDecode(res);

      // fetch image if set in metadata
      if (metadata.containsKey("image") && metadata['image']!.isEmpty != true) {
        String imageCid = getCidFromIpfsLink(metadata['image']!);
        downloadFileFromIPFS(imageCid, "$tokenUri.image.json");
        imagePath = "$tokenUri.image.json";
      }
    } catch (e) {
      print("error $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchResults();
  }

  @override
  Widget build(BuildContext context) {
    final NFTDetailsScreenArguments navArgs =
        ModalRoute.of(context)!.settings.arguments as NFTDetailsScreenArguments;

    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBarWithLogo(
          loginFunction: widget.loginWithMetaMask,
          text: 'NFT Details',
          connectedWallet: widget.connector!.session?.accounts!.isEmpty == true
              ? null
              : widget.connector!.session?.accounts![0].toLowerCase(),
        ),
        body: SafeArea(
            child: Row(
          children: [
            //three Expanded widgets to make the three columns equal width
            Expanded(
              flex: 1,
              child: Container(
                color: Colors.blue,
              ),
            ),
            Expanded(
              flex: 8,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),
                    Text('Token ID: ${navArgs.tokenId}'),
                    if (imagePath != "")
                      Image.file(
                        File(imagePath),
                        height: 200,
                        width: 200,
                      ),
                    if (metadata['title'] != null) SizedBox(height: 20),
                    Text('Item Name: ${metadata['title']}',
                        style: TextStyle(fontSize: 20)),
                    if (metadata['description'] != null) SizedBox(height: 20),
                    Text('Item Description: ${metadata['decription']}',
                        style: TextStyle(fontSize: 20)),
                  ]),
            ),
            Expanded(
              flex: 1,
              child: Container(
                color: Colors.green,
              ),
            ),
          ],
        )));
  }
}
