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

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key, this.connector, this.loginWithMetaMask});

  final WalletConnect? connector;
  final Function? loginWithMetaMask;

  static const routeName = '/result';

  @override
  State<ResultsScreen> createState() => _ResultsScreen();
}

class _ResultsScreen extends State<ResultsScreen> {
  ValueNotifier<String> _statusNotifier = ValueNotifier("");
  String statusText = "";
  String imagePath = "";
  Map<String, String> metadata = {};

  _updateStatusText(String text) {
    _statusNotifier.value = text;
  }

  Future<void> _fetchResults(BigInt tokenId) async {
    try {
      // get IPFS CID
      String tokenUri = await getTokenUri(tokenId);
      _updateStatusText("TOKEN ID: $tokenUri");

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
      _updateStatusText("ERROR: $e");
      print("error $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final navArgs =
        ModalRoute.of(context)!.settings.arguments as GetResultArguments;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBarWithLogo(
        connectedWallet: widget.connector!.session?.accounts!.isEmpty == true
            ? null
            : widget.connector!.session?.accounts![0].toLowerCase(),
        loginFunction: widget.loginWithMetaMask,
        text: 'Initialize Chip (3/3)',
      ),
      body: SafeArea(
          minimum: const EdgeInsets.all(24.0),
          child: Center(
              child: Column(children: [
            ValueListenableBuilder(
                valueListenable: _statusNotifier,
                builder: (context, statusText, child) {
                  return ElevatedButton(
                    onPressed: () =>
                        {_fetchResults(bytesToInt(navArgs.tokenId))},
                    child: Text("get results"),
                  );
                },
                // TODO: SHOW STATUS
                child: Text(statusText)),
            // TODO: SHOW METADATA and IMAGE in a nice way
            Text(metadata["name"]!),
            Text(metadata["description"]!),
          ]))),
    );
  }
}
