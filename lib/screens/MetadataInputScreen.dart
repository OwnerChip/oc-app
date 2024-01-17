//package imports
import 'package:async/async.dart';
import 'package:mime/mime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cross_file/cross_file.dart';
import 'package:ownerchip_whitelabel/services/providers/collectionsData.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:ownerchip_whitelabel/utils/globals.dart';
import 'package:ownerchip_whitelabel/widgets/popups/CustomOverlay.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:ownerchip_whitelabel/widgets/ui/StyledTextInputBox.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:web3dart/web3dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry/sentry.dart';
import 'package:ownerchip_whitelabel/services/providers/nftData.dart';
import 'package:ownerchip_whitelabel/services/providers/attachmentsData.dart';

//misc imports
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/utils/navigationArguments.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/services/providers/chipData.dart';

//screen imports
import 'package:ownerchip_whitelabel/screens/HomeScreen.dart';
import 'package:ownerchip_whitelabel/screens/NFTDetailsScreen.dart';
import 'package:ownerchip_whitelabel/screens/AddAttachmentScreen.dart';

//widget imports
import 'package:ownerchip_whitelabel/widgets/ui/CustomCard.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomAppBar.dart';
import 'package:ownerchip_whitelabel/widgets/ui/SpinningLoadingSvg.dart';
import 'package:ownerchip_whitelabel/widgets/ui/TraitsForm.dart';
import 'package:ownerchip_whitelabel/widgets/ui/SetImageWidget.dart';
import 'package:ownerchip_whitelabel/widgets/popups/WalletPopUp.dart';
import 'package:ownerchip_whitelabel/widgets/ui/AttachmentUploadButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/AttachmentBox.dart';

//service imports
import 'package:ownerchip_whitelabel/services/ipfs.services.dart';
import 'package:ownerchip_whitelabel/services/images.services.dart';
import 'package:ownerchip_whitelabel/services/web3.services.dart';
import 'package:ownerchip_whitelabel/services/backend.services.dart';
import 'package:ownerchip_whitelabel/services/wallet.services.dart';

//theme imports
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/themes/fontSpecs.dart';

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

  @override
  void initState() {
    super.initState();
    metadata = {
      'traits': [],
    };
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
      sendAnalyticsTrace(sessionId, "", "IPFS_UPLOAD_STARTED",
          tags: {'connectedWallet': connectedWallet.hex});
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

      if (cid != '') {
        ipfsProcess.finish();
        sendAnalyticsTrace(sessionId, cid, "IPFS_UPLOAD_FINISHED",
            tags: {'connectedWallet': connectedWallet.hex, 'cid': cid});
      }

      //check if user is allowed to use gas station
      final List response =
          await checkMetaTx(collectionId, mintFunctionSignature);
      final bool canUseGasStation = response[0];
      final metaTxAgreementId = response[1];

      // switch to minting loading overlay
      setState(() {
        isLoading = true;
        overlayContentType = 'loading';
        loadingText = context.loc.mintingToken;
      });

      sendAnalyticsTrace(sessionId, "", "MINTING_STARTED", tags: {
        'connectedWallet': connectedWallet.hex,
        'gasStation': canUseGasStation
      });

      String txnHash;
      if (canUseGasStation) {
        txnHash = await makeAndSendGaslessTx(
            ref,
            ScaffoldKey.getScaffoldKey('MetadataInputScreen').currentContext!,
            mintFunctionSignature,
            chainId,
            voucherCollectionId ?? collectionId,
            signatureData,
            connectedWallet,
            wc,
            wcSession,
            metaTxAgreementId,
            walletType!,
            cid: cid,
            toggleLoading: toggleLoading);
      } else {
        if (userSession.isOwnerCard) {
          throw 'Gas station needed for TX with OwnerCard.';
        }
        if (wc == null) {
          throw 'Please connect with MetaMask or similar wallet.';
        }
        txnHash = await makeAndSendNormalTx(
            ref,
            mintFunctionSignature,
            chainId,
            voucherCollectionId ?? collectionId,
            signatureData,
            connectedWallet,
            wc,
            wcSession!,
            walletType!,
            cid: cid);
      }

      //wait until TX is succeeded or failed
      var txnReceipt =
          await getTxnReceipt(getRPCUrlFromChainId(chainId), txnHash);

      //if transaction is mined, then navigate to NFTDetailsScreen
      if (txnReceipt?.status) {
        mintProcess.finish();
        sendAnalyticsTrace(sessionId, txnHash, "MINTING_SUCCESS", tags: {
          'connectedWallet': connectedWallet.hex,
          'gasStation': canUseGasStation
        });

        await Future.delayed(const Duration(seconds: 2));

        //refresh providers so offer for sale button is shown correctly on NFT Details
        ChipInfoModel chipInfo = ref.read(chipInfoProvider);
        await ref.refresh(findTokenProvider(chipInfo.tokenId).future);
        await ref.refresh(voucherContractAndTwinNftOwnerProvider.future);

        Navigator.pushNamedAndRemoveUntil(
          ScaffoldKey.getScaffoldKey('MetadataInputScreen').currentContext!,
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
    } catch (e, s) {
      // Send message mint error to analytics/ownerchip & Sentry
      sendAnalyticsTrace(sessionId, "$e", "MINTING_ERROR",
          tags: {'connectedWallet': connectedWallet.hex});
      mintProcess.throwable = e;
      mintProcess.status = const SpanStatus.aborted();
      mintProcess.finish();
      await Sentry.captureException(
        e,
        stackTrace: s,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        returnSnackBarWidget(
            context.loc.errorHeadingSnackBar, context.loc.mintError, 'error'),
      );
      setState(() {
        isLoading = false;
      });
    }
    //refresh tokenInfo so it can be loaded; This code is not supposed to be inside try block, so it does not trigger catch if it fails and use does not stay on metadatasecreen with error, despite token minting being successful. User can retrigger manually on next screen
    final ChipInfoModel chipInfo = ref.read(chipInfoProvider);
    TokenChainAndCollection tokenInfo =
        await ref.refresh(findTokenProvider(chipInfo.tokenId).future);
  }

  void toggleTraitsForm() {
    setState(() {
      isLoading = !isLoading;
      overlayContentType = 'traits';
    });
  }

  void setTraits(List traits) {
    setState(() {
      metadata["traits"] = traits;
    });
    toggleTraitsForm();
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
                      Navigator.pushNamedAndRemoveUntil(
                          context, HomeScreen.routeName, (route) => false);
                    }
                  : null,
              loadingText: loadingText,
              svgPath:
                  '${dotenv.get('IMAGE_ASSETS_BASE_URL')}/chip_dark_blue.svg',
              // enable secondary button
              // secondaryButton: true,
              // secondaryButtonText: context.loc.troubleshoot,
              // secondaryButtonUrl: dotenv.get('SUPPORT_PAGE_URL')
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
                    initialTraitsArray: metadata['traits'],
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
                                                      dotenv.get('APP_ID'))
                                                  .customRoundedButtonColor,
                                              fontSize: CustomFonts(
                                                          dotenv.get('APP_ID'))
                                                      .bodyText2FontSize /
                                                  1.3),
                                      text: context.loc.traits,
                                      onPressed: () => toggleTraitsForm()),
                                )
                              ]),
                              const SizedBox(height: 15),
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
                    ])
              ]))),
    );
  }
}
