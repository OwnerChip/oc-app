//flutter imports
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

  final Map<String, String> metadata = {};
  late XFile? image;
  late String imageFilename = "none";
  late String statusText = "";
  bool success = false;

  void setCameraImage() async {
    XFile? imageFile = await getImageFromCamera();
    setState(() {
      image = imageFile;
      imageFilename = (imageFile != null) ? imageFile.name : "";
    });
  }

  void setGalleryImage() async {
    XFile? imageFile = await getImageFromGallery();
    setState(() {
      image = imageFile;
      imageFilename = (imageFile != null) ? imageFile.name : "";
    });
  }

  void _initializeChip(Map<String, String> metadata, {XFile? image}) async {
    loadingText.value = 'Scanning...';
    loading.value = true;
    status.value = '';

    success = false;
    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      var isoDep = IsoDep.from(tag);
      if (isoDep == null) {
        status.value = 'IsoDep is not supported.';
        NfcManager.instance.stopSession();
        return;
      }
      try {
        var selectAppResponse =
            await isoDep.transceive(data: SELECT_APP); //select app

        Uint8List GET_KEY_INFO = make_get_key_info_command(0x01);
        var responseGetKeyInfo = await isoDep.transceive(
            data: GET_KEY_INFO); //check if key[1] already exists
        //check if does not exist yet exist
        if (responseGetKeyInfo[responseGetKeyInfo.length - 2] == 106 &&
            responseGetKeyInfo[responseGetKeyInfo.length - 1] == 136) {
          //key does not exist
          var responseGenerateKey = await isoDep.transceive(data: GENERATE_KEY);
          print("response generate key: $responseGenerateKey");
          var newKeyHandle = responseGenerateKey[0];
        } else {
          setState(() {
            statusText:
            "key already exists";
          });
        }
        NfcManager.instance.stopSession();

        setState(() {
          statusText:
          "Initializing Chip...";
        });

        // upload image to ipfs
        late String imageCid;
        if (image != null) {
          imageCid = await uploadFileToIPFS(image!);
        }
        // add image cid to metadata
        metadata['image'] = 'ipfs://$imageCid';

        // generate JSON file
        XFile jsonFile = generateJsonFile(metadata);

        // upload metadata json to ipfs
        final String cid = await uploadFileToIPFS(jsonFile);

        var mintParams = makeMintParams(
            widget.connector!.session!.accounts[0],
            dotenv.get('CONTRACT_ADDRESS'),
            cid,
            selectAppResponse.sublist(1, 11));

        //metamask interaction
        await launchUrlString(widget.connector!.session.toUri(),
            mode: LaunchMode.externalApplication);

        //TODO: transaction does not always pop up in Metamask!
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
        print("Error transceiving isoDep: $e");
        NfcManager.instance.stopSession();
        setState(() {
          statusText:
          "Error minting token: $e";
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBarWithLogo(
          loginFunction: () => {},
          text: 'Initialize Chip',
          connectedWallet: widget.connector!.session?.accounts!.isEmpty == true
              ? null
              : widget.connector!.session?.accounts![0].toLowerCase(),
        ),
        body: SafeArea(
            child: Center(
                child: Padding(
                    padding: EdgeInsets.all(25.0),
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
                          Text("Selected image: $imageFilename"),
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
                                        _initializeChip(metadata, image: image);
                                      },
                                      child: const Text('Submit'),
                                    ),
                                  ),
                                  Text(statusText)
                                ],
                              ))
                        ])))));
  }
}
