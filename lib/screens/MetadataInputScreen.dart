//flutter imports
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:mime/mime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cross_file/cross_file.dart';
import 'package:owner_chip_admin_demo/themes/BlueTheme.dart';
import 'package:owner_chip_admin_demo/widgets/CustomCard.dart';
import 'package:owner_chip_admin_demo/widgets/CustomImage.dart';
import 'package:owner_chip_admin_demo/widgets/CustomRoundedButton.dart';
import 'package:owner_chip_admin_demo/widgets/CustomPopups.dart';
import 'package:owner_chip_admin_demo/widgets/ScreenBodyLayout.dart';
import '../utils/localization.helper.dart';
import 'package:flutter_svg/flutter_svg.dart';

//web3 imports
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:web3dart/crypto.dart';

//local imports
import '../widgets/CustomAppBar.dart';
import '../utils/ipfs.services.dart';
import '../utils/utils.dart';
import '../utils/images.service.dart';
import '../utils/web3.services.dart';
import '../utils/navigation_arguments.dart';
import '../screens/NFTDetailsScreen.dart';
import '../widgets/LoadingIndicator.dart';
import '../widgets/ChipInfo.dart';
import '../widgets/returnSnackBarWidget.dart';
import 'HomeScreen.dart';
import '../widgets/LoadingOverlay.dart';

//stateful widget with name MetadataScreen
class MetadataScreen extends StatefulWidget {
  const MetadataScreen(
      {super.key,
      required this.connector,
      this.loginWithMetaMask,
      required this.connected});

  final WalletConnect connector;
  final Function? loginWithMetaMask;
  final bool connected;

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
  bool showImageOptions = false;
  bool isLoading = false;
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
    // showLoadingPopUp(context, "UPLOAD");
    setState(() {
      isLoading = true;
      success = false;
      loadingText = context.loc.uploadingMetadata;
    });

    final navArgs =
        ModalRoute.of(context)!.settings.arguments as ChipInitializedArguments;

    //if wc bridge is not connected, then reconnect
    if (!widget.connector.bridgeConnected) {
      widget.connector.reconnect();
    }

    String walletAddress = widget.connector.session.accounts[0].toLowerCase();

    // upload image to ipfs
    String imageCid;
    String cid = '';

    try {
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
      cid = await uploadFileToIPFS(jsonFile, 'application/json');

      String fullUri = "ipfs://$cid";

      // generate mint parameters
      var mintParams = await makeSignedMintParams(
          walletAddress, navArgs.hashedMsg, "ipfs://$cid", navArgs.signature);

      setState(() {
        isLoading = false;
      });
      //metamask interaction
      await launchUrlString('wc:', mode: LaunchMode.externalApplication);

      var txnHash = await widget.connector.sendCustomRequest(
          method: 'eth_sendTransaction',
          params: mintParams,
          id: makeRandomInt());

      setState(() {
        isLoading = true;
        loadingText = context.loc.mintingToken;
      });

      var txnReceipt = await getTxnReceipt(txnHash);

      if (txnReceipt?.status == true) {
        // if (true) {
        // ignore: use_build_context_synchronously
        Navigator.pushReplacementNamed(context, NFTDetailsScreen.routeName,
            arguments: NFTDetailsScreenArguments(widget.loginWithMetaMask,
                navArgs.tokenId, navArgs.chipWalletAddress, image.path));

        setState(() {
          isLoading = false;
          success = true;
        });
      } else {
        throw Exception('Transaction failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        returnSnackBarWidget(
            context.loc.errorHeadingSnackBar, context.loc.mintError, 'error'),
      );
      setState(() {
        success = false;
        isLoading = false;
      });
    }
  }

  void onCameraButtonPressed() {
    setState(() {
      showImageOptions = true;
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
    final navArgs =
        ModalRoute.of(context)!.settings.arguments as ChipInitializedArguments;
    final BlueStyle blueStyle = Theme.of(context).extension<BlueStyle>()!;

    return LoadingOverlay(
      isLoading: isLoading,
      loadingText: loadingText,
      svgPath: 'assets/images/chip_dark_blue.svg',
      child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: CustomAppBar(
            loginFunction: widget.loginWithMetaMask,
            text: '${context.loc.initializeChip}',
            connectedWalletAddress:
                widget.connector.session.accounts.isEmpty == true
                    ? null
                    : widget.connector.session.accounts[0].toLowerCase(),
            connector: widget.connector,
            isConnected: widget.connected,
          ),
          body: ScreenBodyLayout(children: [
            Row(
              children: [
                //spacing
                SizedBox(width: 22),
                RichText(
                  text: TextSpan(
                      text: 'Step 2/',
                      style: Theme.of(context)
                          .textTheme
                          .headline6!
                          .copyWith(fontSize: 18),
                      children: [
                        TextSpan(
                            text: '2',
                            style: Theme.of(context)
                                .textTheme
                                .headline5!
                                .copyWith(fontSize: 18))
                      ]),
                ),
              ],
            ),
            //spacing
            SizedBox(height: 20),
            CustomCard(children: [
              AspectRatio(
                aspectRatio: 0.75,
                child: image != null
                    ? GestureDetector(
                        onTap: () {
                          setState(() {
                            showImageOptions = true;
                            imagePath = 'assets/images/placeholder.jpg';
                            image = null;
                          });
                        },
                        child: CustomImage(
                          loading: false,
                          imagePath: imagePath,
                        ),
                      )
                    : CustomCard(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        mainAxisAlignment: MainAxisAlignment.center,
                        width: double.infinity,
                        children: [
                            showImageOptions
                                ? Column(
                                    children: [
                                      CustomRoundedButton(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          icon: const Icon(
                                              Icons.camera_alt_outlined),
                                          width: 180,
                                          text: context.loc.takePicture,
                                          onPressed: () => setCameraImage()),
                                      SizedBox(height: 10),
                                      CustomRoundedButton(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          icon:
                                              const Icon(Icons.image_outlined),
                                          width: 180,
                                          text: context.loc.selectedImage,
                                          onPressed: () => setGalleryImage()),
                                    ],
                                  )
                                : IconButton(
                                    iconSize: 50,
                                    icon: Icon(Icons.camera_alt_outlined),
                                    color: Theme.of(context).primaryColorLight,
                                    onPressed: () => onCameraButtonPressed(),
                                  ),
                          ]),
              ),
              SizedBox(height: 20),
              // CustomRoundedButton(
              //     // TODO: reduze size / change layout?
              //     text: context.loc.addTraits,
              //     onPressed: () => showTraitInputFormDialog(context)),
              Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.only(left: 12),
                          hintText: context.loc.title,
                        ),
                        onChanged: (text) {
                          metadata['name'] = text;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return context.loc.pleaseEnterText;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      Container(
                        decoration: BoxDecoration(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(13)),
                            boxShadow: [
                              BoxShadow(
                                color: blueStyle.secondaryShadowColor!,
                                offset: Offset(1, 3),
                                blurRadius: 13,
                              )
                            ]),
                        child: TextField(
                          maxLines: 3,
                          keyboardType: TextInputType.multiline,
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            focusColor: Theme.of(context).primaryColorDark,
                            hintText: context.loc.description,
                            filled: true,
                            fillColor:
                                Theme.of(context).scaffoldBackgroundColor,
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                          onChanged: (text) {
                            metadata['description'] = text;
                          },
                        ),
                      )
                    ],
                  )),
              SizedBox(height: 20),
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: CustomRoundedButton(
                    text: context.loc.mintNft,
                    onPressed: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      if (_formKey.currentState!.validate()) {
                        if (image != null) {
                          _initializeChip(metadata, image: image);
                        } else {
                          _initializeChip(metadata);
                        }
                      }
                    },
                  )),
            ])
          ])),
    );
  }
}
