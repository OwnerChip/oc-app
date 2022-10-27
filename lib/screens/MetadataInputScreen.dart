//flutter imports
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cross_file/cross_file.dart';

//nfc imports
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/platform_tags.dart';

//web3 imports
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:url_launcher/url_launcher_string.dart';

//local imports
import '../widgets/AppBarWithLogo.dart';
import '../ipfs/ipfs.services.dart';
import '../nfc/commands.dart';
import '../utils/images.service.dart';
import '../web3/web3.services.dart';
import '../utils/navigation_arguments.dart';

//stateful widget with name MetadataScreen
class MetadataScreen extends StatefulWidget {
  const MetadataScreen({super.key, this.connector});

  final WalletConnect? connector;

  static const routeName = '/metadata-input';

  @override
  State<MetadataScreen> createState() => _MetadataScreen();
}

class _MetadataScreen extends State<MetadataScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  ValueNotifier<dynamic> loading = ValueNotifier(false);
  ValueNotifier<dynamic> loadingText = ValueNotifier('');
  ValueNotifier<dynamic> status = ValueNotifier('');

  Map<String, String> metadata = {};
  XFile? image;
  String imagePath = "none";
  String statusText = "";
  bool success = false;

  void setCameraImage() async {
    XFile? imageFile = await getImageFromCamera();
    setState(() {
      image = imageFile;
      imagePath = (imageFile != null) ? imageFile.path : "";
    });
  }

  void setGalleryImage() async {
    XFile? imageFile = await getImageFromGallery();
    setState(() {
      image = imageFile;
      imagePath = (imageFile != null) ? imageFile.path : "";
    });
  }

  void _initializeChip(
      String walletAddress, Uint8List tokenId, Map<String, String> metadata,
      {XFile? image}) async {
    loadingText.value = 'Scanning...';
    loading.value = true;
    status.value = '';
    success = false;

    // upload image to ipfs
    String imageCid;
    if (image != null) {
      imageCid = await uploadFileToIPFS(image!);
      metadata['image'] = 'ipfs://$imageCid';
    }

    // generate JSON file
    final Directory directory = Directory.systemTemp;
    final File file = File('${directory.path}/metadata.json');
    await file.writeAsString(json.encode(metadata));
    XFile jsonFile = XFile(file.path);

    // upload metadata json to ipfs
    String cid = await uploadFileToIPFS(jsonFile);

    var mintParams = makeMintParams(
        walletAddress, dotenv.get('CONTRACT_ADDRESS'), cid, tokenId);

    //metamask interaction
    await launchUrlString(widget.connector!.session.toUri(),
        mode: LaunchMode.externalApplication);

    //TODO: transaction does not always pop up in Metamask!
    try {
      var txnHash = await widget.connector!.sendCustomRequest(
          method: 'eth_sendTransaction', params: mintParams, id: 1337);

      var txnReceipt = await getTxnReceipt(txnHash);

      if (txnReceipt?.status == true) {
        setState(() {
          statusText:
          "Minted token successfully";
        });
      } else {
        setState(() {
          statusText:
          "Error minting token";
        });
      }

      loading.value = false;
      loadingText.value = '';
      success = true;
    } catch (e) {
      setState(() {
        statusText:
        "Error minting token";
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navArgs =
        ModalRoute.of(context)!.settings.arguments as ChipInitializedArguments;

    //TODO
    String connectedWallet = (navArgs.connector != null)
        ? (navArgs.connector?.session != null)
            ? (navArgs.connector!.session.accounts.isEmpty != true)
                ? navArgs.connector!.session.accounts[0].toLowerCase()
                : "0x"
            : "0x"
        : "0x";

    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBarWithLogo(
            loginFunction: () => {},
            text: 'Initialize Chip (2/3)',
            connectedWallet: (widget.connector != null)
                ? (widget.connector?.session != null)
                    ? (widget.connector!.session.accounts.isEmpty != true)
                        ? widget.connector!.session.accounts[0].toLowerCase()
                        : null
                    : null
                : null),
        body: SafeArea(
            child: Center(
                child: Padding(
                    padding: EdgeInsets.all(15.0),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Please upload an image of the object',
                              style: TextStyle(
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.bold)),
                          Form(
                            child: Column(children: [
                              ElevatedButton(
                                onPressed: () {
                                  setGalleryImage();
                                },
                                child: const Text('Select image'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  setCameraImage();
                                },
                                child: const Text('Take a picture'),
                              )
                            ]),
                          ),
                          if (image != null) Text("Selected image:"),
                          if (image != null)
                            Image.file(
                              File(imagePath),
                              height: 200,
                              width: 200,
                            ),
                          Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10.0)),
                          Text('Please enter your metadata',
                              style: TextStyle(
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.bold)),
                          Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _titleController,
                                    decoration: const InputDecoration(
                                      hintText: 'Title',
                                    ),
                                    onChanged: (text) {
                                      metadata['title'] = text;
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter some text';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 15),
                                  TextField(
                                    maxLines: 2,
                                    keyboardType: TextInputType.multiline,
                                    controller: _descriptionController,
                                    decoration: const InputDecoration(
                                      hintText: 'Description',
                                    ),
                                    onChanged: (text) {
                                      metadata['description'] = text;
                                    },
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16.0),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        if (_formKey.currentState!.validate()) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                                  content:
                                                      Text('Processing ...')));
                                        }
                                        //TODO: how can I show status updates here, if I can NOT call async functions?
                                        if (image != null) {
                                          _initializeChip(connectedWallet,
                                              navArgs.tokenId, metadata,
                                              image: image);
                                        } else {
                                          _initializeChip(connectedWallet,
                                              navArgs.tokenId, metadata);
                                        }
                                      },
                                      child: const Text('Mint NFT'),
                                    ),
                                  ),
                                  Text(statusText)
                                ],
                              ))
                        ])))));
  }
}
