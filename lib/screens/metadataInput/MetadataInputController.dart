import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/screens/metadataInput/MetadataInputScreen.dart';
import 'package:ownerchip_whitelabel/screens/offer/OfferForSaleCreatedTokenScreen.dart';
import 'package:ownerchip_whitelabel/services/backend/app/backendApp.dart';
import 'package:ownerchip_whitelabel/services/backend/metaTx/backendMetaTx.dart';
import 'package:ownerchip_whitelabel/services/images.services.dart';
import 'package:ownerchip_whitelabel/services/ipfs.services.dart';
import 'package:ownerchip_whitelabel/services/providers/chipData.dart';
import 'package:ownerchip_whitelabel/services/providers/collectionsData.dart';
import 'package:ownerchip_whitelabel/services/providers/nftData.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/services/wallet.services.dart';
import 'package:ownerchip_whitelabel/services/web3.services.dart';
import 'package:ownerchip_whitelabel/utils/globals.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:web3dart/web3dart.dart';
import 'package:mime/mime.dart';
import '../../config/ownercard.dart';
import '../../utils/logger.dart';

mixin MetadataInputController on ConsumerState<MetadataScreen> {

  //form state
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  late Map<String, dynamic> metadata;
  XFile? image;
  bool showImageOptions = false;
  bool isLoading = false;
  String overlayContentType = 'loading'; //can be "traits" or "loading"
  String loadingText = '';
  CancelableOperation? cancellableOperation;
  List<Map> traitsStateArray = [];

  void init() {
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

  Future<dynamic> fromCancelable(Future<dynamic> future) async {
    cancellableOperation?.cancel();
    cancellableOperation =
        CancelableOperation.fromFuture(future, onCancel: () {});
    return cancellableOperation;
  }

  void close() {
    titleController.dispose();
    descriptionController.dispose();
    setState(() {
      traitsStateArray = [];
    });
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

  Future<void> createToken(Web3App? wc,
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
    final sessionId = userSession.sessionId;
    final wcSession = ref.read(wcSessionProvider);
    final walletType = ref.read(walletTypeProvider);

    final mintProcess = Sentry.startTransaction('initMinting()', 'task');

    EthereumAddress connectedWallet = ref.read(userAddressProvider);

    try {
      final ipfsProcess = Sentry.startTransaction('initIPFSUpload()', 'task');
      BackendApp.sendAnalyticsTrace(sessionId, "", "IPFS_UPLOAD_STARTED",
          tags: {'connectedWallet': connectedWallet.hex});

      final chipInfo = ref.read(chipInfoProvider);

      String functionSignature = (voucherCollectionId != null)
          ? mintVoucherFunctionSignature
          : mintFunctionSignature;

      if (OwnercardData.isCertificateCard(chipInfo.firstSlotKey)) {
        functionSignature = mintVoucherToCertificateCardFunctionSignature;
      }

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

      XFile jsonFileVoucher = await generateVoucherMetadataFile(
          voucherMetadata, chipInfo.tokenId, context);
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
      await BackendMetaTx.checkMetaTx(collectionId, functionSignature);
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

      Future<String> normalTx() async {
        return await makeAndSendNormalTx(
            context,
            ref,
            functionSignature,
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
          txnHash = await callFunctionWithFallback(
              function: () {
                return makeAndSendGaslessTx(
                    ref,
                    ScaffoldKey
                        .getScaffoldKey('MetadataInputScreen')
                        .currentContext!,
                    functionSignature,
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
              },
              fallback: normalTx,
              predicate: gaslessTransactionFallbackPredicate);
        } else {
          if (wc == null) {
            throw 'Please connect with MetaMask or similar wallet.';
          }

          txnHash = await normalTx();
        }
      } catch (e, st) {
        talker.error('Error minting token: $e', st);
        Sentry.captureException(e, stackTrace: st);
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

}