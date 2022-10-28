import 'package:flutter/material.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import '../widgets/AppBarWithLogo.dart';
import '../utils/navigation_arguments.dart';

class NFTDetailsScreen extends StatelessWidget {
  const NFTDetailsScreen({super.key, this.connector, this.loginWithMetaMask});
  final WalletConnect? connector;
  final Function? loginWithMetaMask;

  static const routeName = '/nft-details';

  @override
  Widget build(BuildContext context) {
    final NFTDetailsScreenArguments navArgs =
        ModalRoute.of(context)!.settings.arguments as NFTDetailsScreenArguments;

    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBarWithLogo(
          loginFunction: loginWithMetaMask,
          text: 'NFT Details',
          connectedWallet: connector!.session?.accounts!.isEmpty == true
              ? null
              : connector!.session?.accounts![0].toLowerCase(),
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
                    SizedBox(height: 20),
                    Text('Item Name:', style: TextStyle(fontSize: 20)),
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
