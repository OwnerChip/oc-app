//flutter imports
import 'dart:convert';
import 'dart:io';
import 'package:mime/mime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cross_file/cross_file.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomCard.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomImage.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';
import '../utils/localization.helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/services/providers.service.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:url_launcher/url_launcher_string.dart';

//local imports
import '../widgets/ui/CustomAppBar.dart';
import '../services/ipfs.services.dart';
import '../utils/utils.dart';
import 'package:ownerchip_whitelabel/services/images.service.dart';
import '../services/web3.services.dart';
import '../utils/navigation.arguments.dart';
import '../screens/NFTDetailsScreen.dart';
import '../widgets/ui/returnSnackBarWidget.dart';
import '../widgets/ui/LoadingOverlay.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import '../widgets/layout/CustomOverlay.dart';
import '../themes/fontSpecs.dart';
import '../widgets/ui/TraitsForm.dart';

//stateful widget with name MetadataScreen
class MetadataScreen extends ConsumerStatefulWidget {
  const MetadataScreen({super.key});

  static const routeName = '/metadata-input';

  @override
  _MetadataScreen createState() => _MetadataScreen();
}

class _MetadataScreen extends ConsumerState<MetadataScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  late Map<String, dynamic> metadata;
  XFile? image;
  String imagePath = '${dotenv.get('IMAGE_ASSETS_BASE_URL')}/placeholder.jpg';
  bool success = false;
  bool showImageOptions = false;
  bool showTraitsForm = false;
  bool isLoading = false;
  String loadingText = '';

  void initState() {
    super.initState();
    metadata = {
      'traits': [],
    };
  }

  void setCameraImage() async {
    XFile? imageFile = await getImageFromCamera();
    setState(() {
      image = imageFile;
      imagePath = (imageFile != null)
          ? imageFile.path
          : '${dotenv.get('IMAGE_ASSETS_BASE_URL')}/placeholder.jpg';
    });
  }

  void setGalleryImage() async {
    XFile? imageFile = await getImageFromGallery();
    setState(() {
      image = imageFile;
      imagePath = (imageFile != null)
          ? imageFile.path
          : '${dotenv.get('IMAGE_ASSETS_BASE_URL')}/placeholder.jpg';
    });
  }

  void initializeChip(WidgetRef ref, Map<String, dynamic> metadata,
      {XFile? image}) async {
    WalletConnect wc = ref.watch(walletConnectProvider);
    final signatureData = ref.watch(signatureDataProvider);
    setState(() {
      isLoading = true;
      success = false;
      loadingText = context.loc.uploadingMetadata;
    });

    //if wc bridge is not connected, then reconnect
    if (!wc.bridgeConnected) {
      wc.reconnect();
    }

    String walletAddress = wc.session.accounts[0].toLowerCase();

    // upload image to ipfs
    String imageCid;
    String cid = '';

    try {
      String mimeType = lookupMimeType(image!.path) ?? "image/jpg";

      if (image != null) {
        imageCid = await uploadFileToIPFS(image, mimeType);
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

      //watch chipInfoProvider
      final chipInfo = await ref.watch(chipInfoProvider);

      //TODO: get chain ID and collection ID from dropdown menu UI!
      final List config = [80001, '0x46f4Cd7c9c6Aca27BECF45Cc5d836dDDac204d32'];
      // generate mint parameters
      var mintParams = await makeSignedMintParams(
          getRPCUrlFromChainId(config[0]),
          config[1],
          walletAddress,
          signatureData.hashedMsg,
          "ipfs://$cid",
          signatureData.signature);

      setState(() {
        isLoading = false;
      });
      //metamask interaction
      await launchUrlString('wc:', mode: LaunchMode.externalApplication);

      var txnHash = await wc.sendCustomRequest(
          method: 'eth_sendTransaction',
          params: mintParams,
          id: makeRandomInt());

      setState(() {
        isLoading = true;
        loadingText = context.loc.mintingToken;
      });

      var txnReceipt =
          await getTxnReceipt(getRPCUrlFromChainId(config[0]), txnHash);

      if (txnReceipt?.status == true) {
        //delay for 1 second
        await Future.delayed(Duration(seconds: 2));
        // ignore: use_build_context_synchronously
        Navigator.pushReplacementNamed(context, NFTDetailsScreen.routeName);

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

  void toggleTraitsForm() {
    setState(() {
      showTraitsForm = !showTraitsForm;
    });
  }

  void setTraits(List traits) {
    setState(() {
      metadata["traits"] = traits;
    });
    toggleTraitsForm();
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
    WalletConnect wc = ref.watch(walletConnectProvider);

    return CustomOverlay(
        show: showTraitsForm,
        content: CustomCard(
            mainAxisSize: MainAxisSize.min,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            withScrollView: true,
            children: [
              Text(
                context.loc.addTraits,
                style: Theme.of(context).textTheme.headline2,
              ),
              SizedBox(height: 10),
              Material(
                  child: TraitsForm(
                submitFunction: setTraits,
                toggleTraitsForm: toggleTraitsForm,
                initialTraitsArray: metadata['traits'],
              ))
            ]),
        child: LoadingOverlay(
          onPressed: loadingText == context.loc.mintingToken
              ? () {
                  setState(() {
                    isLoading = false;
                  });
                }
              : null,
          isLoading: isLoading,
          loadingText: loadingText,
          svgPath: '${dotenv.get('IMAGE_ASSETS_BASE_URL')}/chip_dark_blue.svg',
          child: Scaffold(
              extendBodyBehindAppBar: true,
              appBar: CustomAppBar(
                text: '${context.loc.initializeChip}',
                connectedWalletAddress: wc.session.accounts.isEmpty == true
                    ? null
                    : wc.session.accounts[0].toLowerCase(),
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
                CustomCard(
                    color: CustomColors(dotenv.get('APP_ID')).cardColor,
                    children: [
                      AspectRatio(
                        aspectRatio: 0.75,
                        child: image != null
                            ? GestureDetector(
                                onTap: () {
                                  setState(() {
                                    showImageOptions = true;
                                    imagePath =
                                        '${dotenv.get('IMAGE_ASSETS_BASE_URL')}/placeholder.jpg';
                                    image = null;
                                  });
                                },
                                child: CustomImage(
                                  loading: false,
                                  imagePath: imagePath,
                                  imageFile: image,
                                ),
                              )
                            : CustomCard(
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                                mainAxisAlignment: MainAxisAlignment.center,
                                width: double.infinity,
                                children: [
                                    showImageOptions
                                        ? Column(
                                            children: [
                                              CustomRoundedButton(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  icon: Icon(
                                                      Icons.camera_alt_outlined,
                                                      color: CustomColors(dotenv
                                                              .get('APP_ID'))
                                                          .metadataImagePickerIconsColor),
                                                  width: 180,
                                                  text: context.loc.takePicture,
                                                  onPressed: () =>
                                                      setCameraImage()),
                                              SizedBox(height: 10),
                                              CustomRoundedButton(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  icon: Icon(
                                                      Icons.image_outlined,
                                                      color: CustomColors(dotenv
                                                              .get('APP_ID'))
                                                          .metadataImagePickerIconsColor),
                                                  width: 180,
                                                  text: context.loc.selectImage,
                                                  onPressed: () =>
                                                      setGalleryImage()),
                                            ],
                                          )
                                        : IconButton(
                                            iconSize: 50,
                                            icon:
                                                Icon(Icons.camera_alt_outlined),
                                            color: Theme.of(context)
                                                .primaryColorLight,
                                            onPressed: () =>
                                                onCameraButtonPressed(),
                                          ),
                                  ]),
                      ),
                      SizedBox(height: 20),
                      Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              Row(children: [
                                Expanded(
                                  flex: 5,
                                  child: TextFormField(
                                    style:
                                        Theme.of(context).textTheme.bodyText2,
                                    controller: _titleController,
                                    decoration: InputDecoration(
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Theme.of(context)
                                                  .primaryColor),
                                        ),
// and:
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Theme.of(context)
                                                  .primaryColor),
                                        ),
                                        contentPadding:
                                            EdgeInsets.only(left: 12),
                                        hintText: context.loc.title,
                                        hintStyle: Theme.of(context)
                                            .textTheme
                                            .bodyText2),
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
                                ),
                                Expanded(
                                  flex: 3,
                                  child: CustomRoundedButton(
                                      height: 25,
                                      // width: 100,
                                      textStyle: Theme.of(context)
                                          .textTheme
                                          .bodyText1!
                                          .copyWith(
                                              color: CustomColors(
                                                      dotenv.get('APP_ID'))
                                                  .customRoundedButtonColor,
                                              fontSize: CustomFonts(
                                                          dotenv.get('APP_ID'))
                                                      .bodyText2FontSize /
                                                  1.3),
                                      // TODO: reduze size / change layout?
                                      text: context.loc.traits,
                                      onPressed: () => toggleTraitsForm()),
                                )
                              ]),
                              const SizedBox(height: 15),
                              Container(
                                decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(13)),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            CustomColors(dotenv.get('APP_ID'))
                                                .secondaryShadowColor!,
                                        offset: Offset(1, 3),
                                        blurRadius: 13,
                                      )
                                    ]),
                                child: TextField(
                                  style: Theme.of(context).textTheme.bodyText2,
                                  maxLines: 3,
                                  keyboardType: TextInputType.multiline,
                                  controller: _descriptionController,
                                  decoration: InputDecoration(
                                    focusColor:
                                        Theme.of(context).primaryColorDark,
                                    hintText: context.loc.description,
                                    hintStyle:
                                        Theme.of(context).textTheme.bodyText2,
                                    filled: true,
                                    fillColor: Theme.of(context)
                                        .scaffoldBackgroundColor,
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
                                  initializeChip(ref, metadata, image: image);
                                } else {
                                  initializeChip(ref, metadata);
                                }
                              }
                            },
                          )),
                    ])
              ])),
        ));
  }
}
