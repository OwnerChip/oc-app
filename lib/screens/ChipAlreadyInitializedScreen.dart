import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:convert/convert.dart';
import '../utils/localization.helper.dart';

//web3 imports
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web3dart/crypto.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';

// import local files
import '../widgets/AppBarWithLogo.dart';
import '../utils/navigation_arguments.dart';
import '../utils/url_generator.service.dart';
import 'HomeScreen.dart';
import '../utils/utils.dart';
import '../utils/web3.services.dart';
import '../widgets/returnSnackBarWidget.dart';

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
  bool loading = false;
  String loadingText = '';

  Future<void> burnToken(Uint8List tokenIdHash, MsgSignature signature) async {
    setState(() {
      loading = true;
      loadingText = context.loc.burnToken;
    });
    try {
      var burnParams = await makeSignedBurnParams(
          widget.connector.session.accounts[0], tokenIdHash, signature);

      await launchUrlString('wc:', mode: LaunchMode.externalApplication);
      var txnHash = await widget.connector.sendCustomRequest(
          method: 'eth_sendTransaction',
          params: burnParams,
          id: makeRandomInt());

      var txnReceipt = await getTxnReceipt(txnHash);
      if (txnReceipt?.status == true) {
        //this means burn succeeded
        ScaffoldMessenger.of(context).showSnackBar(
          returnSnackBarWidget(context.loc.successHeadingSnackbar,
              context.loc.burnedSuccess, 'success'),
        );
        //delay 1 second
        await Future.delayed(Duration(seconds: 1));

        //navigate to login screen
        // ignore: use_build_context_synchronously
        Navigator.pushReplacementNamed(context, HomeScreen.routeName);
        setState(() {
          loading = false;
          loadingText = '';
        });
      } else {
        throw Exception(context.loc.burnedError);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        returnSnackBarWidget(
            context.loc.errorHeadingSnackBar, context.loc.burnedError, 'error'),
      );
      setState(() {
        loading = false;
        loadingText = '';
      });
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

    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBarWithLogo(
          loginFunction: () => {},
          text: context.loc.initializeChip,
          connectedWallet: widget.connector.session.accounts.isEmpty == true
              ? null
              : widget.connector.session.accounts[0].toLowerCase(),
          connector: widget.connector,
          connected: widget.connected,
        ),
        body: SafeArea(
            child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Row(
              children: [
                Expanded(
                    flex: 2,
                    child: Row(
                      children: [],
                    )),
                Expanded(
                    flex: 10,
                    child: Column(
                      children: [
                        //bold red text
                        Text(
                          context.loc.warning,
                          style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 28,
                              fontWeight: FontWeight.bold),
                        ),
                        //spacing
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: const [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.orange,
                                      size: 40,
                                    ),
                                  ],
                                )),
                            //spacing
                            const SizedBox(width: 10),
                            Expanded(
                                flex: 10,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      context.loc.alreadyLinked,
                                    )
                                  ],
                                ))
                          ],
                        ),
                        //spacing
                        const SizedBox(
                          height: 50,
                        ),

                        SizedBox(
                          width: 200,
                          height: 50,
                          child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                              ),
                              onPressed: loading
                                  ? null
                                  : () => {burnToken(tokenIdHash, signature)},
                              child: loading
                                  ? const CircularProgressIndicator(
                                      color: Colors.grey,
                                    )
                                  : Text(context.loc.burnToken)),
                        ),
                        const SizedBox(
                          height: 40,
                        ),
                        SizedBox(
                          width: 200,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                            ),
                            onPressed: () => {
                              launchUrl(
                                  generateBlockchainExplorerTokenDetailsUrl(
                                      tokenId.toString()))
                            },
                            child: Text(context.loc.showOnExplorer),
                          ),
                        ),
                        //spacing
                        const SizedBox(
                          height: 8,
                        ),
                        SizedBox(
                          width: 200,
                          height: 50,
                          child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                              ),
                              onPressed: () => {
                                    launchUrl(generateOpenSeaTokenDetailsUrl(
                                        bytesToUnsignedInt(tokenId).toString()))
                                  },
                              child: Text(context.loc.showOnOpenSea)),
                        ),
                        const SizedBox(
                          height: 40,
                        ),
                        SizedBox(
                          width: 200,
                          height: 50,
                          child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey, // background
                              ),
                              onPressed: () => {
                                    Navigator.pushNamed(
                                        context, HomeScreen.routeName)
                                  },
                              child: Text(context.loc.cancel)),
                        ),
                      ],
                    )),
                Expanded(
                    flex: 2,
                    child: Column(
                      children: [],
                    )),
              ],
            ),
          ]),
        )));
  }
}
