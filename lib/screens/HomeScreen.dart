//flutter imports
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

//nfc imports
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/platform_tags.dart';
import 'package:owner_chip_admin_demo/screens/MetadataInputScreen.dart';

//web3 imports
import 'package:web3dart/crypto.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:url_launcher/url_launcher_string.dart';

//local imports
import '../nfc/commands.dart';
import '../utils/utils.dart';
import '../web3/web3.services.dart';
import 'LoginScreen.dart';
import 'MetadataInputScreen.dart';

//local widgets
import '../widgets/LoadingIndicator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    Key? key,
    this.connector,
  }) : super(key: key);

  final WalletConnect? connector;

  static const routeName = '/home';

  @override
  State<StatefulWidget> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  ValueNotifier<dynamic> loading = ValueNotifier(false);
  ValueNotifier<dynamic> loadingText = ValueNotifier('');
  ValueNotifier<dynamic> status = ValueNotifier('');
  String image = '';
  bool success = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.appTitle)),
        body: SafeArea(
          child: FutureBuilder<bool>(
            future: NfcManager.instance.isAvailable(),
            builder: (context, ss) => ss.data != true
                ? Center(child: Text('NfcManager.isAvailable(): ${ss.data}'))
                : Flex(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    direction: Axis.vertical,
                    children: [
                      Flexible(
                        flex: 2,
                        child: Container(
                          margin: EdgeInsets.all(4),
                          constraints: BoxConstraints.expand(),
                          decoration: BoxDecoration(border: Border.all()),
                          child: SingleChildScrollView(
                              child: Column(
                            children: [
                              ValueListenableBuilder<dynamic>(
                                  valueListenable: status,
                                  builder: (context, value, _) => Column(
                                        children: [
                                          Text('${value ?? ''}'),
                                          Padding(
                                              padding: EdgeInsets.all(20),
                                              child:
                                                  image.length != 0 && success
                                                      ? Image.asset(image)
                                                      : null)
                                        ],
                                      )),
                              ValueListenableBuilder(
                                valueListenable: loadingText,
                                builder: (context, value, _) => Padding(
                                  padding: EdgeInsets.all(8),
                                  child: loading.value
                                      ? LoadingIndicator(
                                          loadingText: loadingText.value)
                                      : null,
                                ),
                              ),
                            ],
                          )),
                        ),
                      ),
                      Flexible(
                        flex: 3,
                        child: GridView.count(
                          padding: EdgeInsets.all(4),
                          crossAxisCount: 2,
                          childAspectRatio: 4,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                          children: [
                            ElevatedButton(
                                child: Text(AppLocalizations.of(context)!
                                    .initializeChip),
                                onPressed: () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                      builder: ((context) =>
                                          const MetadataScreen())));
                                }),
                            ElevatedButton(
                                child: Text(
                                    AppLocalizations.of(context)!.checkOwner),
                                onPressed: _checkOwner),
                            ElevatedButton(
                                child: Text(AppLocalizations.of(context)!
                                    .getWalletAddress),
                                onPressed: _getWalletAddress),
                            ElevatedButton(
                                child: Text(
                                    AppLocalizations.of(context)!.burnToken),
                                onPressed: _burnToken),
                            ElevatedButton(
                                child:
                                    Text(AppLocalizations.of(context)!.logout),
                                onPressed: () => {
                                      widget.connector!.killSession(),
                                      // Navigator.pushReplacementNamed(
                                      //     context, LoginScreen.routeName),
                                    }),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  void _checkOwner() async {
    loadingText.value = 'Scanning...';
    loading.value = true;
    status.value = '';
    image = '';
    success = false;
    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      var isoDep = IsoDep.from(tag);
      if (isoDep == null) {
        status.value = 'IsoDep is not supported.';
        NfcManager.instance.stopSession();
        return;
      }
      try {
        var selectAppResponse = await isoDep.transceive(data: SELECT_APP);

        //convert Uint8List to int
        var tokenId = bytesToInt(selectAppResponse.sublist(1, 11));

        loadingText.value = 'Checking owner...';

        final owner = await getOwner(tokenId);

        if (owner == widget.connector!.session!.accounts[0].toLowerCase()) {
          status.value = 'You are the owner!';
          success = true;
          image = 'assets/images/checkmark.png';
        } else {
          status.value = 'Owner is $owner';
        }

        loading.value = false;
        loadingText.value = '';
      } catch (e) {
        print("Error transceiving isoDep: $e");
        NfcManager.instance.stopSession();
        loading.value = false;
        loadingText.value = '';
        status.value = "Error checking owner: $e";
        image = '';
      }
    });
  }

  void _burnToken() async {
    loadingText.value = AppLocalizations.of(context)!.scanning + '...';
    loading.value = true;
    status.value = '';
    image = '';
    success = false;
    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      var isoDep = IsoDep.from(tag);
      if (isoDep == null) {
        status.value = AppLocalizations.of(context)!.nfcError;
        NfcManager.instance.stopSession();
        return;
      }
      try {
        var selectAppResponse = await isoDep.transceive(data: SELECT_APP);

        final contractAddress = dotenv.env['CONTRACT_ADDRESS'];

        var burnParams = makeBurnParams(widget.connector!.session!.accounts[0],
            contractAddress!, selectAppResponse.sublist(1, 11));

        loadingText.value = AppLocalizations.of(context)!.burning + '...';

        await launchUrlString(widget.connector!.session.toUri(),
            mode: LaunchMode.externalApplication);
        var txnHash = await widget.connector!.sendCustomRequest(
            method: 'eth_sendTransaction', params: burnParams, id: 1338);

        var txnReceipt = await getTxnReceipt(txnHash);

        if (txnReceipt?.status == true) {
          //this means mint succeeded
          status.value = AppLocalizations.of(context)!.burnedSuccess;
        } else {
          status.value = AppLocalizations.of(context)!.burnedError;
        }
        loading.value = false;
        loadingText.value = '';
        success = true;
        image = 'assets/images/flame.png';
      } catch (e) {
        print("Error transceiving isoDep: $e");
        NfcManager.instance.stopSession();
        loading.value = false;
        loadingText.value = '';
        status.value = "Error burning token: $e";
        image = '';
      }
    });
  }

  void _getWalletAddress() {
    loadingText.value = AppLocalizations.of(context)!.scanning + '...';
    loading.value = true;
    status.value = '';
    image = '';
    success = false;
    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      var isoDep = IsoDep.from(tag);
      if (isoDep == null) {
        status.value = 'IsoDep is not supported.';
        NfcManager.instance.stopSession(errorMessage: status.value);
        return;
      }
      Uint8List GET_KEY_INFO = make_get_key_info_command(0x01);
      try {
        await isoDep.transceive(data: SELECT_APP);
        var responseGetKeyInfo = await isoDep.transceive(
            data: GET_KEY_INFO); //gets wallet address of first generated wallet
        NfcManager.instance.stopSession();
        var uin8key = responseGetKeyInfo.sublist(9, 73); //get 64 bit public key
        var uint8Address = publicKeyToAddress(uin8key);
        var walletAddress = makeHexFromUint8List(uint8Address);
        status.value = "Wallet address: $walletAddress";
        loading.value = false;
        loadingText.value = '';
        success = true;
      } catch (e) {
        print("Error transceiving isoDep: $e");
        NfcManager.instance.stopSession(errorMessage: status.value);
        loading.value = false;
        loadingText.value = '';
        status.value = AppLocalizations.of(context)!.nfcError + ": $e";
        image = '';
      }
    });
  }
}
