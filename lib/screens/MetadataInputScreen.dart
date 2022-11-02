//flutter imports
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:mime/mime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
import '../utils/utils.dart';
import '../utils/images.service.dart';
import '../web3/web3.services.dart';
import '../utils/navigation_arguments.dart';
import '../screens/NFTDetailsScreen.dart';

//stateful widget with name MetadataScreen
class MetadataScreen extends StatefulWidget {
  const MetadataScreen({super.key, this.connector, this.loginWithMetaMask});

  final WalletConnect? connector;
  final Function? loginWithMetaMask;

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
    loadingText.value = AppLocalizations.of(context)!.scanning + '...';
    loading.value = true;
    status.value = '';
    success = false;

    // upload image to ipfs
    String imageCid;
    String mimeType = lookupMimeType(image!.path) ?? "image/jpg";
    if (image != null) {
      imageCid = await uploadFileToIPFS(image!, mimeType);
      metadata['image'] = 'ipfs://$imageCid';
    }

    // generate JSON file
    final Directory directory = Directory.systemTemp;
    final File file = File('${directory.path}/metadata.json');
    await file.writeAsString(json.encode(metadata));
    XFile jsonFile = XFile(file.path);

    // upload metadata json to ipfs
    String cid = await uploadFileToIPFS(jsonFile, 'application/json');

    // generate mint parameters
    var mintParams = makeMintParams(
        walletAddress, dotenv.get('CONTRACT_ADDRESS'), "ipfs://$cid", tokenId);

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
          statusText = AppLocalizations.of(context)!.mintSuccess;
        });
      } else {
        setState(() {
          statusText = AppLocalizations.of(context)!.mintError;
        });
      }

      loading.value = false;
      loadingText.value = '';
      success = true;
    } catch (e) {
      setState(() {
        statusText = AppLocalizations.of(context)!.mintError;
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

    setState(() {
      statusText = AppLocalizations.of(context)!.alreadyLinked;
    });

    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBarWithLogo(
            loginFunction: widget.loginWithMetaMask,
            text: AppLocalizations.of(context)!.initializeChip + ' (2/3)',
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
                          Text(AppLocalizations.of(context)!.uploadImage,
                              style: TextStyle(
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.bold)),
                          Form(
                            child: Column(children: [
                              ElevatedButton(
                                onPressed: () {
                                  setGalleryImage();
                                },
                                child: Text(
                                    AppLocalizations.of(context)!.selectImage),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  setCameraImage();
                                },
                                child: Text(
                                    AppLocalizations.of(context)!.takePicture),
                              )
                            ]),
                          ),
                          if (image != null)
                            Text(AppLocalizations.of(context)!.selectedImage),
                          if (image != null)
                            Image.file(
                              File(imagePath),
                              height: 200,
                              width: 200,
                            ),
                          Padding(
                              padding: EdgeInsets.symmetric(vertical: 10.0)),
                          Text(AppLocalizations.of(context)!.enterMetadata,
                              style: TextStyle(
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.bold)),
                          Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _titleController,
                                    decoration: InputDecoration(
                                      hintText:
                                          AppLocalizations.of(context)!.title,
                                    ),
                                    onChanged: (text) {
                                      metadata['title'] = text;
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return AppLocalizations.of(context)!
                                            .enterText;
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 15),
                                  TextField(
                                    maxLines: 2,
                                    keyboardType: TextInputType.multiline,
                                    controller: _descriptionController,
                                    decoration: InputDecoration(
                                      hintText: AppLocalizations.of(context)!
                                          .description,
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
                                              .showSnackBar(SnackBar(
                                                  content: Text(
                                                      AppLocalizations.of(
                                                                  context)!
                                                              .processing +
                                                          '...')));
                                        }
                                        if (image != null) {
                                          _initializeChip(connectedWallet,
                                              navArgs.tokenId, metadata,
                                              image: image);
                                        } else {
                                          _initializeChip(connectedWallet,
                                              navArgs.tokenId, metadata);
                                        }
                                        // TODO: change screen after SUCCESS message only!
                                        Future.delayed(
                                            Duration(milliseconds: 1000), () {
                                          Navigator.pushNamed(context,
                                              NFTDetailsScreen.routeName,
                                              arguments: NFTDetailsScreenArguments(
                                                  widget.connector,
                                                  widget.loginWithMetaMask,
                                                  BigInt.from(
                                                      convertUint8ListToDecimal(
                                                          navArgs.tokenId)),
                                                  navArgs.chipWalletAddress));
                                        });
                                      },
                                      child: Text(AppLocalizations.of(context)!
                                          .mintNft),
                                    ),
                                  ),
                                  Text(statusText)
                                ],
                              ))
                        ])))));
  }
}
