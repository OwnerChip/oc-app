//flutter imports
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:mime/mime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cross_file/cross_file.dart';
import '../utils/localization.helper.dart';

//web3 imports
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:web3dart/crypto.dart';

//local imports
import '../widgets/AppBarWithLogo.dart';
import '../ipfs/ipfs.services.dart';
import '../utils/utils.dart';
import '../utils/images.service.dart';
import '../web3/web3.services.dart';
import '../utils/navigation_arguments.dart';
import '../screens/NFTDetailsScreen.dart';
import '../widgets/LoadingIndicator.dart';
import '../widgets/ChipInfo.dart';

//stateful widget with name MetadataScreen
class MetadataScreen extends StatefulWidget {
  const MetadataScreen(
      {super.key, required this.connector, this.loginWithMetaMask});

  final WalletConnect connector;
  final Function? loginWithMetaMask;

  static const routeName = '/metadata-input';

  @override
  State<MetadataScreen> createState() => _MetadataScreen();
}

class _MetadataScreen extends State<MetadataScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  Map<String, String> metadata = {};
  XFile? image;
  String imagePath = 'assets/images/placeholder.jpg';
  bool success = false;
  bool loading = false;
  String loadingText = '';

  void setCameraImage() async {
    XFile? imageFile = await getImageFromCamera();
    setState(() {
      image = imageFile;
      imagePath = (imageFile != null)
          ? imageFile.path
          : 'assets/images/placeholder.jpg';
    });
  }

  void setGalleryImage() async {
    XFile? imageFile = await getImageFromGallery();
    setState(() {
      image = imageFile;
      imagePath = (imageFile != null)
          ? imageFile.path
          : 'assets/images/placeholder.jpg';
    });
  }

  void _initializeChip(Map<String, String> metadata, {XFile? image}) async {
    setState(() {
      loading = true;
      loadingText = "${context.loc.uploadingMetadata} ...";
      success = false;
    });

    final navArgs =
        ModalRoute.of(context)!.settings.arguments as ChipInitializedArguments;

    String walletAddress = widget.connector.session.accounts[0].toLowerCase();

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
    String fullUri = "ipfs://$cid";

    // generate mint parameters
    var mintParams = makeMintParams(walletAddress,
        dotenv.get('CONTRACT_ADDRESS'), fullUri, navArgs.signature);

    // metamask interaction
    await launchUrlString(widget.connector!.session.toUri(),
        mode: LaunchMode.externalApplication);

    // TODO: transaction does not always pop up in Metamask!
    try {
      //metamask interaction
      await launchUrlString('wc:', mode: LaunchMode.externalApplication);
      var txnHash = await widget.connector?.sendCustomRequest(
          method: 'eth_sendTransaction',
          params: mintParams,
          id: makeRandomInt());

      setState(() {
        loadingText = '${context.loc.mintingToken} ...';
      });

      var txnReceipt = await getTxnReceipt(txnHash);

      if (txnReceipt?.status == true) {
        setState(() {
          success = true;
          loading = false;
        });

        // ignore: use_build_context_synchronously
        Navigator.pushNamed(context, NFTDetailsScreen.routeName,
            arguments: NFTDetailsScreenArguments(
                bytesToInt(navArgs.tokenId), navArgs.chipWalletAddress));
      } else {
        throw Exception('Transaction failed');
      }
    } catch (e) {
      setState(() {
        success = false;
        loading = false;
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
    final navArgs = ModalRoute.of(context)!.settings.arguments
        as ChipAlreadyInitializedScreenArguments;

    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBarWithLogo(
          loginFunction: widget.loginWithMetaMask,
          text: '${context.loc.initializeChip} (2/3)',
          connectedWallet: widget.connector?.session?.accounts!.isEmpty == true
              ? null
              : widget.connector?.session?.accounts![0].toLowerCase(),
          connector: widget.connector,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
              child: Padding(
                  padding: EdgeInsets.all(15.0),
                  child: Column(children: [
                    ChipInfo(
                        tokenId: bytesToInt(navArgs.tokenId),
                        chipName: 'Secora Infineon',
                        walletAddress: navArgs.chipWalletAddress),
                    SizedBox(height: 20),
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
                                  return context.loc.pleaseEnterText;
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
                          ],
                        )),
                    //spacing
                    SizedBox(height: 20),

                    //row with height 100

                    Row(
                      //space evenly
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        //image with aspect ratio of 1
                        Container(
                          width: 150,
                          height: 150,
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: image != null
                                ? Image.file(
                                    File(image!.path),
                                    fit: BoxFit.cover,
                                  )
                                : Image.asset(
                                    imagePath,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),

                        Column(
                          children: [
                            //button with fixed width
                            Container(
                              width: 150,
                              child: ElevatedButton(
                                onPressed: () {
                                  setCameraImage();
                                },
                                child: Text(context.loc.takePicture),
                              ),
                            ),
                            Container(
                              width: 150,
                              child: ElevatedButton(
                                onPressed: () {
                                  setGalleryImage();
                                },
                                child: Text(context.loc.selectedImage),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                    SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: (loading
                          ? LoadingIndicator(loadingText: loadingText)
                          : ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  if (image != null) {
                                    _initializeChip(metadata, image: image);
                                  } else {
                                    _initializeChip(metadata);
                                  }
                                }
                              },
                              child: Text(context.loc.mintNft),
                            )),
                    ),
                  ]))),
        ));
  }
}
