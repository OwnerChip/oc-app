// ignore_for_file: use_build_context_synchronously

//package imports
import 'package:async/async.dart';
import 'package:mime/mime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cross_file/cross_file.dart';
import 'package:web3dart/web3dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:url_launcher/url_launcher_string.dart';

//misc imports
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';

//screen imports
import 'package:ownerchip_whitelabel/screens/HomeScreen.dart';
import 'package:ownerchip_whitelabel/screens/NFTDetailsScreen.dart';

//widget imports
import 'package:ownerchip_whitelabel/widgets/ui/CustomCard.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomImage.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomAppBar.dart';
import 'package:ownerchip_whitelabel/widgets/ui/returnSnackBarWidget.dart';
import 'package:ownerchip_whitelabel/widgets/ui/LoadingOverlay.dart';
import 'package:ownerchip_whitelabel/widgets/layout/CustomOverlay.dart';
import 'package:ownerchip_whitelabel/widgets/ui/TraitsForm.dart';

//service imports
import 'package:ownerchip_whitelabel/services/ipfs.services.dart';
import 'package:ownerchip_whitelabel/services/images.service.dart';
import 'package:ownerchip_whitelabel/services/web3.services.dart';
import 'package:ownerchip_whitelabel/services/backend.services.dart';
import 'package:ownerchip_whitelabel/services/providers.service.dart';
import 'package:ownerchip_whitelabel/services/walletconnect.services.dart';

//theme imports
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/themes/fontSpecs.dart';

//stateful widget with name MetadataScreen
class MetadataScreen extends ConsumerStatefulWidget {
  const MetadataScreen({super.key});

  static const routeName = '/metadata-input';

  @override
  _MetadataScreen createState() => _MetadataScreen();
}

class _MetadataScreen extends ConsumerState<MetadataScreen> {
  //form state
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  late Map<String, dynamic> metadata;
  XFile? image;
  String imagePath = '${dotenv.get('IMAGE_ASSETS_BASE_URL')}/placeholder.jpg';
  bool showImageOptions = false;
  bool showTraitsForm = false;
  bool isLoading = false;
  String loadingText = '';
  CancelableOperation? cancellableOperation;

  @override
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

  Future<void> createToken(WalletConnect wc, SignatureData signatureData,
      Map<String, dynamic> metadata, int chainId, EthereumAddress collectionId,
      {XFile? image}) async {
    setState(() {
      isLoading = true;
      loadingText = context.loc.uploadingMetadata;
    });

    //if wc bridge is not connected, then reconnect
    if (!wc.bridgeConnected) {
      wc.reconnect();
    }

    //get wallet address
    EthereumAddress walletAddress =
        EthereumAddress.fromHex(wc.session.accounts[0].toLowerCase());

    try {
      //upload image to ipfs
      String imageCid;
      String cid = '';
      String mimeType = lookupMimeType(image!.path) ?? "image/jpg";
      imageCid = await uploadFileToIPFS(image, mimeType);
      metadata['image'] = 'ipfs://$imageCid';

      //generate metadata JSON file
      XFile jsonFile = await saveMetadataAsJSONFile(metadata);

      //upload metadata json to ipfs
      cid = await uploadFileToIPFS(jsonFile, 'application/json');

      setState(() {
        isLoading = false;
      });

      //open metamask application
      await launchUrlString('wc:', mode: LaunchMode.externalApplication);

      //check if user is allowed to use gas station
      final List response =
          await checkMetaTx(collectionId, gaslessMintFunctionSignature);
      final bool canUseGasStation = response[0];
      final metaTxAgreementId = response[1];

      setState(() {
        isLoading = true;
        loadingText = context.loc.mintingToken;
      });

      String txnHash;
      if (canUseGasStation) {
        txnHash = await makeAndSendGaslessTx(
            gaslessMintFunctionSignature,
            chainId,
            collectionId,
            signatureData,
            walletAddress,
            wc,
            metaTxAgreementId,
            cid: cid);
      } else {
        // generate mint parameters
        txnHash = await makeAndSendNormalTx(mintFunctionSignature, chainId,
            collectionId, signatureData, walletAddress, wc,
            cid: cid);
      }

      //get transaction receipt
      var txnReceipt =
          await getTxnReceipt(getRPCUrlFromChainId(chainId), txnHash);

      //if transaction is mined, then navigate to NFTDetailsScreen
      if (txnReceipt?.status) {
        await Future.delayed(const Duration(seconds: 2));
        Navigator.pushNamedAndRemoveUntil(
          context,
          NFTDetailsScreen.routeName,
          (Route route) => route.isFirst,
        );
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          returnSnackBarWidget(context.loc.successHeadingSnackbar,
              context.loc.mintSuccess, 'success'),
        );
      } else {
        throw Exception('Transaction failed');
      }
    } catch (e) {
      //TODO: Send message mint error to analytics/ownerchip
      ScaffoldMessenger.of(context).showSnackBar(
        returnSnackBarWidget(
            context.loc.errorHeadingSnackBar, context.loc.mintError, 'error'),
      );
      setState(() {
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
    TraitsFormState.traitsArray.clear();
    super.dispose();
  }

  Future<dynamic> fromCancelable(Future<dynamic> future) async {
    cancellableOperation?.cancel();
    cancellableOperation =
        CancelableOperation.fromFuture(future, onCancel: () {});
    return cancellableOperation;
  }

  @override
  Widget build(BuildContext context) {
    WalletConnect wc = ref.watch(walletConnectProvider);
    final int chainId = ref.watch(selectedChainIdProvider);
    final EthereumAddress collectionId =
        ref.watch(selectedCollectionIdProvider);
    final SignatureData signatureData = ref.watch(signatureDataProvider);
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
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 10),
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
                  cancellableOperation?.cancel();
                  setState(() {
                    isLoading = false;
                  });
                  Navigator.pushNamedAndRemoveUntil(
                      context, HomeScreen.routeName, (route) => false);
                }
              : null,
          isLoading: isLoading,
          loadingText: loadingText,
          svgPath: '${dotenv.get('IMAGE_ASSETS_BASE_URL')}/chip_dark_blue.svg',
          child: Scaffold(
              extendBodyBehindAppBar: true,
              appBar: CustomAppBar(
                text: context.loc.initializeChip,
                connectedWalletAddress: wc.session.accounts.isEmpty == true
                    ? null
                    : wc.session.accounts[0].toLowerCase(),
              ),
              body: ScreenBodyLayout(children: [
                Row(
                  children: [
                    const SizedBox(width: 22),
                    RichText(
                      text: TextSpan(
                          text: 'Step 2/',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge!
                              .copyWith(fontSize: 18),
                          children: [
                            TextSpan(
                                text: '2',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall!
                                    .copyWith(fontSize: 18))
                          ]),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                CustomCard(
                    color: CustomColors(dotenv.get('STYLE_ID')).cardColor,
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
                                                              .get('STYLE_ID'))
                                                          .metadataImagePickerIconsColor),
                                                  width: 180,
                                                  text: context.loc.takePicture,
                                                  onPressed: () =>
                                                      setCameraImage()),
                                              const SizedBox(height: 10),
                                              CustomRoundedButton(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  icon: Icon(
                                                      Icons.image_outlined,
                                                      color: CustomColors(dotenv
                                                              .get('STYLE_ID'))
                                                          .metadataImagePickerIconsColor),
                                                  width: 180,
                                                  text: context.loc.selectImage,
                                                  onPressed: () =>
                                                      setGalleryImage()),
                                            ],
                                          )
                                        : IconButton(
                                            iconSize: 50,
                                            icon: const Icon(
                                                Icons.camera_alt_outlined),
                                            color: Theme.of(context)
                                                .primaryColorLight,
                                            onPressed: () =>
                                                onCameraButtonPressed(),
                                          ),
                                  ]),
                      ),
                      const SizedBox(height: 20),
                      Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              Row(children: [
                                Expanded(
                                  flex: 5,
                                  child: TextFormField(
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
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
                                            const EdgeInsets.only(left: 12),
                                        hintText: context.loc.title,
                                        hintStyle: Theme.of(context)
                                            .textTheme
                                            .bodyMedium),
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
                                          .bodyLarge!
                                          .copyWith(
                                              color: CustomColors(
                                                      dotenv.get('STYLE_ID'))
                                                  .customRoundedButtonColor,
                                              fontSize: CustomFonts(dotenv
                                                          .get('STYLE_ID'))
                                                      .bodyText2FontSize /
                                                  1.3),
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
                                            CustomColors(dotenv.get('STYLE_ID'))
                                                .secondaryShadowColor,
                                        offset: const Offset(1, 3),
                                        blurRadius: 13,
                                      )
                                    ]),
                                child: TextField(
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  maxLines: 3,
                                  keyboardType: TextInputType.multiline,
                                  controller: _descriptionController,
                                  decoration: InputDecoration(
                                    focusColor:
                                        Theme.of(context).primaryColorDark,
                                    hintText: context.loc.description,
                                    hintStyle:
                                        Theme.of(context).textTheme.bodyMedium,
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
                      const SizedBox(height: 20),
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: CustomRoundedButton(
                            text: context.loc.mintNft,
                            onPressed: () async {
                              FocusManager.instance.primaryFocus?.unfocus();
                              if (_formKey.currentState!.validate()) {
                                fromCancelable(createToken(wc, signatureData,
                                    metadata, chainId, collectionId,
                                    image: image));
                              }
                            },
                          )),
                    ])
              ])),
        ));
  }
}
