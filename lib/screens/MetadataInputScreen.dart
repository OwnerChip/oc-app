//package imports
import 'package:async/async.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mime/mime.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/domain/attachment/attachment.dart';
import 'package:ownerchip_whitelabel/domain/attachmentType/attachmentType.dart';
import 'package:ownerchip_whitelabel/domain/chipInfoModel/chipInfoModel.dart';
import 'package:ownerchip_whitelabel/domain/signatureData/signatureData.dart';
import 'package:ownerchip_whitelabel/domain/userSession/userSession.dart';
import 'package:ownerchip_whitelabel/screens/AddAttachmentScreen.dart';
//screen imports
import 'package:ownerchip_whitelabel/screens/NFTDetailsScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cross_file/cross_file.dart';
import 'package:ownerchip_whitelabel/screens/offer/OfferForSaleCreatedTokenScreen.dart';
import 'package:ownerchip_whitelabel/services/backend/app/backendApp.dart';
import 'package:ownerchip_whitelabel/services/backend/metaTx/backendMetaTx.dart';
import 'package:ownerchip_whitelabel/services/images.services.dart';
//service imports
import 'package:ownerchip_whitelabel/services/ipfs.services.dart';
import 'package:ownerchip_whitelabel/services/providers/attachmentsData.dart';
import 'package:ownerchip_whitelabel/services/providers/chipData.dart';
import 'package:ownerchip_whitelabel/services/providers/collectionsData.dart';
import 'package:ownerchip_whitelabel/services/providers/nftData.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/services/wallet.services.dart';
import 'package:ownerchip_whitelabel/services/web3.services.dart';
//theme imports
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/globals.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';
import 'package:ownerchip_whitelabel/utils/navigationArguments.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';
import 'package:ownerchip_whitelabel/widgets/popups/CustomOverlay.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:ownerchip_whitelabel/widgets/ui/AttachmentBox.dart';
import 'package:ownerchip_whitelabel/widgets/ui/AttachmentUploadButton.dart';
//widget imports
import 'package:ownerchip_whitelabel/widgets/ui/CustomCard.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/SetImageWidget.dart';
import 'package:ownerchip_whitelabel/widgets/ui/SpinningLoadingSvg.dart';
import 'package:ownerchip_whitelabel/widgets/ui/StyledTextInputBox.dart';
import 'package:ownerchip_whitelabel/widgets/ui/TraitsForm.dart';
import 'package:ownerchip_whitelabel/widgets/ui/appBar/CustomAppBar.dart';
import 'package:sentry/sentry.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

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
  bool showImageOptions = false;
  bool isLoading = false;
  String overlayContentType = 'loading'; //can be "traits" or "loading"
  String loadingText = '';
  CancelableOperation? cancellableOperation;
  List<Map> traitsStateArray = [];

  @override
  void initState() {
    super.initState();
    metadata = {
      'traits': [],
    };
    setState(
      () {
        traitsStateArray = [
          {"trait_type": "Creator", "value": ""},
          {"trait_type": "Medium", "value": ""},
          {"trait_type": "Size", "value": ""},
          {"trait_type": "Year", "value": ""}
        ];
      },
    );
  }

  void resetImage() {
    setState(() {
      image = null;
    });
  }

  Future<XFile> setCameraImage() async {
    XFile? imageFile = await getImageFromCamera();
    setState(() {
      image = imageFile;
    });
    return imageFile!;
  }

  Future<XFile> setGalleryImage() async {
    XFile? imageFile = await getImageFromGallery();
    setState(() {
      image = imageFile;
    });
    return imageFile!;
  }

  Future<void> toggleLoading() async {
    setState(() {
      isLoading = !isLoading;
    });
  }

  Future<void> createToken(
      String sessionId,
      Web3App? wc,
      SignatureData signatureData,
      Map<String, dynamic> metadata,
      int chainId,
      EthereumAddress collectionId,
      EthereumAddress? voucherCollectionId,
      {XFile? image}) async {
    setState(() {
      isLoading = true;
      overlayContentType = 'loading';
      loadingText = context.loc.uploadingMetadata;
    });

    final UserSession userSession = ref.read(userSessionProvider)!;
    final wcSession = ref.read(wcSessionProvider);
    final walletType = ref.read(walletTypeProvider);

    final mintProcess = Sentry.startTransaction('initMinting()', 'task');

    EthereumAddress connectedWallet = ref.read(userAddressProvider);

    try {
      final ipfsProcess = Sentry.startTransaction('initIPFSUpload()', 'task');
      BackendApp.sendAnalyticsTrace(sessionId, "", "IPFS_UPLOAD_STARTED",
          tags: {'connectedWallet': connectedWallet.hex});

      /////////// TWIN METADATA ///////////
      String twinTokenMetadataCID = '';

      //upload image to ipfs
      String imageCid;
      String mimeType = lookupMimeType(image!.path) ?? "image/jpg";
      imageCid = await uploadFileToIPFS(image, mimeType);
      metadata['image'] = 'ipfs://$imageCid';

      //generate twin metadata JSON file
      XFile jsonFileTwin = await saveMetadataAsJSONFile(metadata);

      //upload twin metadata json to ipfs
      twinTokenMetadataCID =
          await uploadFileToIPFS(jsonFileTwin, 'application/json');

      /////////// VOUCHER METADATA ///////////

      Map<String, dynamic> voucherMetadata = {...metadata};
      XFile jsonFileVoucher =
          await generateVoucherMetadataFile(voucherMetadata, context);
      String voucherTokenMetadataCID =
          await uploadFileToIPFS(jsonFileVoucher, 'application/json');

      if (twinTokenMetadataCID != '' || voucherTokenMetadataCID != '') {
        ipfsProcess.finish();
        BackendApp.sendAnalyticsTrace(
            sessionId, twinTokenMetadataCID, "IPFS_UPLOAD_FINISHED", tags: {
          'connectedWallet': connectedWallet.hex,
          'cid': twinTokenMetadataCID
        });
      }

      //check if user is allowed to use gas station
      final List response =
          await BackendMetaTx.checkMetaTx(collectionId, mintFunctionSignature);
      final bool canUseGasStation = response[0];
      final metaTxAgreementId = response[1];

      // switch to minting loading overlay
      setState(() {
        isLoading = true;
        overlayContentType = 'loading';
        loadingText = context.loc.mintingToken;
      });

      BackendApp.sendAnalyticsTrace(sessionId, "", "MINTING_STARTED", tags: {
        'connectedWallet': connectedWallet.hex,
        'gasStation': canUseGasStation
      });

      String txnHash = "";

      Future<void> normalTx() async {
        txnHash = await makeAndSendNormalTx(
            context,
            ref,
            (voucherCollectionId != null)
                ? mintVoucherFunctionSignature
                : mintFunctionSignature,
            chainId,
            voucherCollectionId ?? collectionId,
            signatureData,
            connectedWallet,
            wc!,
            wcSession,
            walletType!,
            twinTokenMetadataCID: twinTokenMetadataCID,
            voucherTokenMetadataCID: voucherTokenMetadataCID);
      }

      try {
        if (canUseGasStation) {
          txnHash = await makeAndSendGaslessTx(
              ref,
              ScaffoldKey.getScaffoldKey('MetadataInputScreen').currentContext!,
              (voucherCollectionId != null)
                  ? mintVoucherFunctionSignature
                  : mintFunctionSignature,
              chainId,
              voucherCollectionId ?? collectionId,
              signatureData,
              connectedWallet,
              wc,
              wcSession,
              metaTxAgreementId,
              walletType!,
              twinTokenMetadataCID: twinTokenMetadataCID,
              voucherTokenMetadataCID: voucherTokenMetadataCID,
              toggleLoading: toggleLoading);
        } else {
          if (userSession.isOwnerCard) {
            throw 'Gas station needed for TX with OwnerCard.';
          }
          if (wc == null) {
            throw 'Please connect with MetaMask or similar wallet.';
          }

          await normalTx();
        }
      } catch (e, st) {
        talker.error('Error minting token: $e', st);
        Sentry.captureException(e, stackTrace: st);
        await normalTx();
      }

      //wait until TX is succeeded or failed
      var txnReceipt =
          await getTxnReceipt(getRPCUrlFromChainId(chainId), txnHash);

      //if transaction is mined, then navigate to NFTDetailsScreen
      if (txnReceipt?.status == true) {
        mintProcess.finish();
        BackendApp.sendAnalyticsTrace(sessionId, txnHash, "MINTING_SUCCESS",
            tags: {
              'connectedWallet': connectedWallet.hex,
              'gasStation': canUseGasStation
            });

        try {
          await Future.delayed(const Duration(seconds: 2));
          //refresh providers so offer for sale button is shown correctly on NFT Details
          ChipInfoModel chipInfo = ref.read(chipInfoProvider);
          await ref.refresh(findTokenProvider(chipInfo.tokenId).future);
          await ref.refresh(voucherContractAndTwinNftOwnerProvider.future);
        } catch (e, st) {
          Sentry.captureException(
            e,
            stackTrace: st,
          );
          talker.error(
            'Error refreshing providers: $e',
            st,
          );
        }

        if (mounted) {
          isLoading = false;
          setState(() {});
        }

        Navigator.of(context).pushNamedAndRemoveUntil(
          OfferForSaleCreatedTokenScreen.routeName,
          (route) => route.isFirst,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          returnSnackBarWidget(context.loc.successHeadingSnackbar,
              context.loc.mintSuccess, 'success'),
        );
      } else {
        throw Exception('Transaction failed');
      }
    } catch (e, s) {
      // Send message mint error to analytics/ownerchip & Sentry
      BackendApp.sendAnalyticsTrace(sessionId, "$e", "MINTING_ERROR",
          tags: {'connectedWallet': connectedWallet.hex});
      mintProcess.throwable = e;
      mintProcess.status = const SpanStatus.aborted();
      mintProcess.finish();
      await Sentry.captureException(
        e,
        stackTrace: s,
      );
      talker.error('Error minting token: $e', s);
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
      isLoading = !isLoading;
      overlayContentType = 'traits';
    });
  }

  void setTraits(List traits) {
    setState(() {
      metadata["traits"] = traits.where((trait) {
        return trait["trait_type"].isNotEmpty && trait["value"].isNotEmpty;
      }).toList();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    setState(() {
      traitsStateArray = [];
    });
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
    final navArgs = ModalRoute.of(context)!.settings.arguments
        as MetadataInputScreenArguments;
    final wc = ref.watch(wcProvider);
    int chainId = navArgs.chainId;
    EthereumAddress collectionId = navArgs.collectionId;
    EthereumAddress? voucherCollectionId = navArgs.voucherAddress;
    final SignatureData signatureData = ref.watch(chipSignatureDataProvider);
    final AsyncValue<List<Attachment>> fetchedAttachments =
        ref.watch(fetchAttachmentsProvider);
    final List<Attachment>? attachmentList =
        ref.watch(localAttachmentsProvider);

    return CustomOverlay(
      show: isLoading,
      content: overlayContentType == 'loading'
          ? SpinningLoadingSvg(
              onPressed: loadingText == context.loc.mintingToken
                  ? () {
                      cancellableOperation?.cancel();
                      setState(() {
                        isLoading = false;
                      });
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  : null,
              loadingText: loadingText,
              svgPath:
                  '${dotenv.get('IMAGE_ASSETS_BASE_URL')}/chip_dark_blue.svg',
            )
          : CustomCard(
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
                    traitsStateArray: traitsStateArray,
                  ))
                ]),
      child: Scaffold(
          key: ScaffoldKey.getScaffoldKey('MetadataInputScreen'),
          extendBodyBehindAppBar: true,
          appBar: CustomAppBar(
            text: context.loc.initializeChip,
          ),
          body: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: ScreenBodyLayout(children: [
                Row(
                  children: [
                    const SizedBox(width: 22),
                    RichText(
                      text: TextSpan(
                          text: '${context.loc.step} 2/',
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
                    color: CustomColors(dotenv.get('APP_ID')).cardColor,
                    children: [
                      SetImageWidget(
                        imageFile: image,
                        setCameraImage: setCameraImage,
                        setGalleryImage: setGalleryImage,
                        resetImage: resetImage,
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
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Theme.of(context)
                                                  .primaryColor),
                                        ),
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
                              ]),
                              const SizedBox(height: 15),
                              TraitsForm(
                                submitFunction: setTraits,
                                toggleTraitsForm: toggleTraitsForm,
                                traitsStateArray: traitsStateArray,
                              ),
                              StyledTextInputBox(
                                controller: _descriptionController,
                                setText: (input) =>
                                    metadata['description'] = input,
                                keyboardType: TextInputType.multiline,
                                maxlines: 3,
                                fillColor:
                                    Theme.of(context).scaffoldBackgroundColor,
                                hintText: context.loc.description,
                              ),
                            ],
                          )),
                      const SizedBox(height: 20),

                      AttachmentUploadButton(
                          text: context.loc.uploadDigitalContent,
                          icon: Icons.add),
                      const SizedBox(height: 20),
                      //map over attachmentList to display all attachments as FileBox
                      if (attachmentList != null)
                        for (var i = 0; i < attachmentList.length; i++)
                          Column(
                            children: [
                              AttachmentBox(
                                text: attachmentList[i].title,
                                icon:
                                    attachmentList[i].type == AttachmentType.url
                                        ? Icons.link
                                        : Icons.attach_file,
                                isPrivate: attachmentList[i].isPrivate,
                                onTap: () {
                                  //navigate to AddFileScreen with navigation args
                                  Navigator.pushNamed(
                                      context, AddAttachmentScreen.routeName,
                                      arguments: AttachmentScreensArguments(
                                          true, attachmentList[i].type,
                                          index: i));
                                },
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),

                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: CustomRoundedButton(
                            text: context.loc.mintNft,
                            onPressed: () async {
                              FocusManager.instance.primaryFocus?.unfocus();
                              if (_formKey.currentState!.validate()) {
                                setTraits(traitsStateArray);
                                fromCancelable(createToken(
                                    navArgs.sessionId,
                                    wc,
                                    signatureData,
                                    metadata,
                                    chainId,
                                    collectionId,
                                    voucherCollectionId,
                                    image: image));
                              }
                            },
                          )),
                      // const SizedBox(height: 60),
                      Row(
                        children: [
                          const SizedBox(width: 20),
                          SvgPicture.asset(
                              "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/triangle_small.svg",
                              width: 25,
                              height: 25),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(context.loc.warningPublicData,
                                style: Theme.of(context).textTheme.bodySmall!),
                          ),
                        ],
                      )
                    ])
              ]))),
    );
  }
}
