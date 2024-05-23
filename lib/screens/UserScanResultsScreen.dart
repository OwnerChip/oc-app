//import packages
import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ownerchip_whitelabel/config/chains.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/domain/blockchainCollectionList/blockchainCollectionList.dart';
import 'package:ownerchip_whitelabel/domain/chipInfoModel/chipInfoModel.dart';
import 'package:ownerchip_whitelabel/domain/collection/collection.dart';
import 'package:ownerchip_whitelabel/domain/creatorData/creatorData.dart';
import 'package:ownerchip_whitelabel/domain/phygital/purchase/purchase.dart';
import 'package:ownerchip_whitelabel/domain/signatureData/signatureData.dart';
import 'package:ownerchip_whitelabel/domain/tokenChainAndCollection/tokenChainAndCollection.dart';
import 'package:ownerchip_whitelabel/domain/userSession/userSession.dart';
import 'package:ownerchip_whitelabel/screens/HomeScreen.dart';
//import screens
import 'package:ownerchip_whitelabel/screens/NFTDetailsScreen.dart';
import 'package:ownerchip_whitelabel/services/attachments.services.dart';
import 'package:ownerchip_whitelabel/services/backend.services.dart';
import 'package:ownerchip_whitelabel/services/nfc.services.dart';
import 'package:ownerchip_whitelabel/services/providers/blockchainData.dart';
import 'package:ownerchip_whitelabel/services/providers/chipData.dart';
import 'package:ownerchip_whitelabel/services/providers/collectionsData.dart';
import 'package:ownerchip_whitelabel/services/providers/nftData.dart';
import 'package:ownerchip_whitelabel/services/providers/purchasesData.dart';
import 'package:ownerchip_whitelabel/services/providers/urlData.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/services/rarible.services.dart';
//import services
import 'package:ownerchip_whitelabel/services/wallet.services.dart';
import 'package:ownerchip_whitelabel/services/web3.services.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/globals.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';
import 'package:ownerchip_whitelabel/widgets/popups/CustomOverlay.dart';
import 'package:ownerchip_whitelabel/widgets/popups/WalletPopUp.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CreatorDataBoxContent.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomAppBar.dart';
//import widgets
import 'package:ownerchip_whitelabel/widgets/ui/CustomCard.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomImage.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomOutlinedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/RefreshMetadataButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/SpinningLoadingSvg.dart';
import 'package:sentry/sentry.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

class UserScanResultsScreen extends ConsumerStatefulWidget {
  const UserScanResultsScreen({super.key});

  static const routeName = '/user-scan-results';

  @override
  _UserScanResultsScreenState createState() => _UserScanResultsScreenState();
}

class _UserScanResultsScreenState extends ConsumerState<UserScanResultsScreen> {
  bool loadingImage = true;

  CancelableOperation? cancellableOperation;

  bool isLoading = false;
  bool isRotating = true;
  String loadingSvgPath =
      '${dotenv.get('IMAGE_ASSETS_BASE_URL')}/chip_dark_blue.svg';
  String loadingText = '';

  Future<void> toggleLoading() async {
    setState(() {
      isLoading = !isLoading;
    });
  }

  Future<void> burnToken(Web3App? wc, BigInt tokenId,
      SignatureData signatureData, EthereumAddress connectedWallet) async {
    final UserSession userSession = ref.read(userSessionProvider)!;
    final wcSession = ref.read(wcSessionProvider);
    final walletType = ref.read(walletTypeProvider);
    final String sessionId = ref.read(userSessionProvider)!.sessionId;
    final TokenChainAndCollection config =
        await ref.watch(findTokenProvider(tokenId).future);
    final burnProcess = Sentry.startTransaction('initBurn()', 'task');

    if (signatureData.hasBeenUsedInSmartContract) {
      ScaffoldMessenger.of(context).showSnackBar(
        returnSnackBarWidget(context.loc.attention,
            context.loc.pleaseScanChipAgainToBurn, 'warning'),
      );
      return;
    }

    try {
      setState(() {
        isLoading = true;
        loadingText = context.loc.burning;
        isRotating = true;
        loadingSvgPath =
            '${dotenv.get('IMAGE_ASSETS_BASE_URL')}/chip_dark_blue.svg';
      });

      sendAnalyticsTrace(sessionId.toString(), "", "BURN_STARTED", tags: {
        'connectedWallet': connectedWallet.hex,
        'chipWallet':
            convertTokenIdToEthereumAddress(ref.read(chipInfoProvider).tokenId)
      });

      final List response =
          await checkMetaTx(config.collectionId, burnFunctionSignature);
      final bool canUseGasStation = response[0];
      final metaTxAgreementId = response[1];

      String txnHash;

      if (canUseGasStation) {
        txnHash = await makeAndSendGaslessTx(
            ref,
            ScaffoldKey.getScaffoldKey('UserScanResultsScreen').currentContext!,
            burnFunctionSignature,
            config.chainId,
            config.collectionId,
            signatureData,
            connectedWallet,
            wc,
            wcSession,
            metaTxAgreementId,
            walletType!,
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
            burnFunctionSignature,
            config.chainId,
            config.collectionId,
            signatureData,
            connectedWallet,
            wc,
            wcSession!,
            walletType!);
      }

      var txnReceipt =
          await getTxnReceipt(getRPCUrlFromChainId(config.chainId), txnHash);
      if (txnReceipt?.status) {
        //this means burn succeeded
        setState(() {
          isRotating = false;
          loadingSvgPath = "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/burn.svg";
          loadingText = context.loc.burnedSuccess;
        });

        deleteAllAttachments(userSession, connectedWallet, config.chainId,
            config.collectionId, tokenId, signatureData);
        // send status to analytics
        burnProcess.finish();
        sendAnalyticsTrace(sessionId, txnHash, "BURN_SUCCESS", tags: {
          'connectedWallet': connectedWallet.hex,
          'chipWallet': convertTokenIdToEthereumAddress(
              ref.read(chipInfoProvider).tokenId)
        });

        await Future.delayed(const Duration(seconds: 2));

        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        throw Exception(context.loc.burnedError);
      }
    } catch (e, s) {
      setState(() {
        isLoading = false;
      });
      // send Error to analytics
      burnProcess.throwable = e;
      burnProcess.status = const SpanStatus.aborted();
      burnProcess.finish();
      sendAnalyticsTrace(sessionId, "", "BURN_ERROR", tags: {
        'error': e,
        'connectedWallet': connectedWallet.hex,
        'chipWallet':
            convertTokenIdToEthereumAddress(ref.read(chipInfoProvider).tokenId)
      });
      await Sentry.captureException(e, stackTrace: s);
      ScaffoldMessenger.of(context).showSnackBar(
        returnSnackBarWidget(
            context.loc.errorHeadingSnackBar, context.loc.burnedError, 'error'),
      );
      print("Error: $e");
    }
  }

  Future<void> claimToken(Web3App? wc, BigInt tokenId,
      SignatureData signatureData, EthereumAddress connectedWallet) async {
    final wcSession = ref.watch(wcSessionProvider);
    final walletType = ref.read(walletTypeProvider);
    UserSession userSession = ref.read(userSessionProvider)!;
    String sessionId = ref.read(userSessionProvider)!.sessionId;
    final TokenChainAndCollection config =
        await ref.watch(findTokenProvider(tokenId).future);
    final claimProcess = Sentry.startTransaction('initClaim()', 'task');

    try {
      setState(() {
        isLoading = true;
        loadingText = context.loc.receivingToken;
      });

      sendAnalyticsTrace(sessionId.toString(), "", "CLAIM_STARTED", tags: {
        'connectedWallet': connectedWallet.hex,
        'chipWallet':
            convertTokenIdToEthereumAddress(ref.read(chipInfoProvider).tokenId)
      });

      final List response =
          await checkMetaTx(config.collectionId, transferFromFunctionSignature);
      final bool canUseGasStation = response[0];
      final metaTxAgreementId = response[1];

      String txnHash;

      if (canUseGasStation) {
        txnHash = await makeAndSendGaslessTx(
            ref,
            ScaffoldKey.getScaffoldKey('UserScanResultsScreen').currentContext!,
            transferFromFunctionSignature,
            config.chainId,
            config.collectionId,
            signatureData,
            connectedWallet,
            wc,
            wcSession,
            metaTxAgreementId,
            walletType!,
            tokenId: tokenId,
            toggleLoading: toggleLoading);
      } else {
        if (userSession.isOwnerCard) {
          throw 'Cannot pay gas for normal transaction with OwnerCard.';
        }
        if (wc == null) {
          throw 'Please connect with MetaMask or similar wallet.';
        }
        txnHash = await makeAndSendNormalTx(
            ref,
            transferFromFunctionSignature,
            config.chainId,
            config.collectionId,
            signatureData,
            connectedWallet,
            wc,
            wcSession!,
            walletType!);
      }

      var txnReceipt =
          await getTxnReceipt(getRPCUrlFromChainId(config.chainId), txnHash);
      if (txnReceipt?.status) {
        ref
            .read(chipSignatureDataProvider.notifier)
            .updateHasBeenUsedInSmartContract(true);
        //this means claiming token succeeded
        setState(() {
          isRotating = false;
          loadingSvgPath = "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/mint.svg";
          loadingText = context.loc.transferSuccess;
        });

        // send status to analytics
        claimProcess.finish();
        sendAnalyticsTrace(sessionId, txnHash, "CLAIM_SUCCESS", tags: {
          'connectedWallet': connectedWallet.hex,
          'chipWallet': convertTokenIdToEthereumAddress(
              ref.read(chipInfoProvider).tokenId)
        });

        //wait for 2 seconds, to make sure corrrect data is fetched by providers

        try {
          await Future.delayed(const Duration(seconds: 2));

          //update providers for burn and transfer buttons
          await ref.refresh(nftApprovalProvider.future);
          await ref.refresh(nftOwnerProvider.future);
          ChipInfoModel chipInfo = ref.read(chipInfoProvider);
          await ref.refresh(findTokenProvider(chipInfo.tokenId).future);
          await ref.refresh(voucherContractAndTwinNftOwnerProvider.future);
        } catch (e) {
          print(e);
          Sentry.captureException(e);
        }

        setState(() {
          isLoading = false;
        });
      } else {
        throw Exception(context.loc.transferError);
      }
    } catch (e, s) {
      setState(() {
        isLoading = false;
      });
      // send Error to analytics
      claimProcess.throwable = e;
      claimProcess.status = const SpanStatus.aborted();
      claimProcess.finish();
      sendAnalyticsTrace(sessionId, "", "CLAIM_ERROR", tags: {
        'connectedWallet': connectedWallet.hex,
        'chipWallet':
            convertTokenIdToEthereumAddress(ref.read(chipInfoProvider).tokenId)
      });
      await Sentry.captureException(e, stackTrace: s);
      ScaffoldMessenger.of(context).showSnackBar(
        returnSnackBarWidget(context.loc.errorHeadingSnackBar,
            context.loc.transferError, 'error'),
      );
      print("Error: $e");
    }
  }

  Future<void> recoverToken(Web3App? wc, BigInt tokenId,
      SignatureData signatureData, EthereumAddress connectedWallet) async {
    final UserSession userSession = ref.read(userSessionProvider)!;
    final wcSession = ref.read(wcSessionProvider);
    final walletType = ref.read(walletTypeProvider);
    String sessionId = ref.read(userSessionProvider)!.sessionId;
    final TokenChainAndCollection config =
        await ref.watch(findTokenProvider(tokenId).future);

    if (signatureData.hasBeenUsedInSmartContract) {
      ScaffoldMessenger.of(context).showSnackBar(
        returnSnackBarWidget(context.loc.attention,
            context.loc.pleaseScanChipAgainToCancel, 'warning'),
      );
      return;
    }

    try {
      setState(() {
        isLoading = true;
        loadingText = 'Recover token';
        isRotating = true;
        loadingSvgPath =
            '${dotenv.get('IMAGE_ASSETS_BASE_URL')}/chip_dark_blue.svg';
      });

      final List response =
          await checkMetaTx(config.collectionId, recoverTokenFunctionSignature);
      final bool canUseGasStation = response[0];
      final metaTxAgreementId = response[1];

      final EthereumAddress controllerContractAddress = EthereumAddress.fromHex(
          chainConfig[config.chainId]!.controllerContract);

      String txnHash;
      if (canUseGasStation) {
        txnHash = await makeAndSendGaslessTx(
            ref,
            ScaffoldKey.getScaffoldKey('UserScanResultsScreen').currentContext!,
            recoverTokenFunctionSignature,
            config.chainId,
            config.collectionId,
            signatureData,
            connectedWallet,
            wc,
            wcSession,
            metaTxAgreementId,
            walletType!,
            controllerContractId: controllerContractAddress,
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
          recoverTokenFunctionSignature,
          config.chainId,
          controllerContractAddress,
          signatureData,
          connectedWallet,
          wc,
          wcSession!,
          walletType!,
        );
      }

      var txnReceipt =
          await getTxnReceipt(getRPCUrlFromChainId(config.chainId), txnHash);
      if (txnReceipt?.status) {
        ref
            .read(chipSignatureDataProvider.notifier)
            .updateHasBeenUsedInSmartContract(true);
        sendAnalyticsTrace(
            userSession.sessionId, txnHash, "TOKEN_RECOVERY_SUCCESS",
            tags: {
              'connectedWallet': ref.read(userAddressProvider).hex,
              'chipWallet': convertTokenIdToEthereumAddress(
                  ref.read(chipInfoProvider).tokenId),
            });

        ScaffoldMessenger.of(context).showSnackBar(
          returnSnackBarWidget(
              context.loc.successHeadingSnackbar, 'Token recovered', 'success'),
        );

        try {
          await Future.delayed(const Duration(seconds: 2));

          //refresh providers for ownerchip check on ResultScreen
          await ref.refresh(nftOwnerProvider.future);
          await ref.refresh(creatorDataProvider.future);
          await ref.refresh(voucherContractAndTwinNftOwnerProvider.future);
          await ref.refresh(activeOffersProvider.future);
        } catch (e) {
          print(e);
          Sentry.captureException(e);
        }

        setState(() {
          isRotating = false;
          loadingSvgPath = "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/mint.svg";
          loadingText = context.loc.offerCanceled;
        });

        setState(() {
          isLoading = false;
        });
      } else {
        throw Exception('Error recovering token.');
      }
    } catch (e, s) {
      Sentry.captureException(e);
      setState(() {
        isLoading = false;
      });
      sendAnalyticsTrace(
          userSession.sessionId, e.toString(), "TOKEN_RECOVERY_ERROR",
          tags: {
            'connectedWallet': ref.read(userAddressProvider).hex,
            'chipWallet': convertTokenIdToEthereumAddress(
                ref.read(chipInfoProvider).tokenId),
          });
      ScaffoldMessenger.of(context).showSnackBar(
        returnSnackBarWidget(context.loc.errorHeadingSnackBar,
            'Error recovering token', 'error'),
      );
    }
  }

  Future<void> cancelOffer(Web3App? wc, BigInt tokenId,
      SignatureData signatureData, EthereumAddress connectedWallet) async {
    final UserSession userSession = ref.read(userSessionProvider)!;
    final wcSession = ref.read(wcSessionProvider);
    final walletType = ref.read(walletTypeProvider);
    String sessionId = ref.read(userSessionProvider)!.sessionId;
    final TokenChainAndCollection config =
        await ref.watch(findTokenProvider(tokenId).future);

    if (signatureData.hasBeenUsedInSmartContract) {
      ScaffoldMessenger.of(context).showSnackBar(
        returnSnackBarWidget(context.loc.attention,
            context.loc.pleaseScanChipAgainToCancel, 'warning'),
      );
      return;
    }

    try {
      setState(() {
        isLoading = true;
        loadingText = context.loc.cancelOffer;
        isRotating = true;
        loadingSvgPath =
            '${dotenv.get('IMAGE_ASSETS_BASE_URL')}/chip_dark_blue.svg';
      });

      final List response = await checkMetaTx(
          config.collectionId, cancelMarketplaceOfferSignature);
      final bool canUseGasStation = response[0];
      final metaTxAgreementId = response[1];

      final EthereumAddress controllerContractAddress = EthereumAddress.fromHex(
          chainConfig[config.chainId]!.controllerContract);

      //fetch order data from backend
      CreatorData creatorData = await ref.read(creatorDataProvider.future);
      final allOffers =
          creatorData.tokenForWhichCreatorDataWasRequested.activeOffers;
      final offer = allOffers.firstWhere((o) => o.isCancelled == false);

      //get calldata from rarible API (prepareCancelTx)
      String cancelTxCalldata = await prepareRaribleOrderCancellation(
          config.chainId, offer.offchainOfferId);

      String txnHash;
      if (canUseGasStation) {
        txnHash = await makeAndSendGaslessTx(
            ref,
            ScaffoldKey.getScaffoldKey('UserScanResultsScreen').currentContext!,
            cancelMarketplaceOfferSignature,
            config.chainId,
            config.collectionId,
            signatureData,
            connectedWallet,
            wc,
            wcSession,
            metaTxAgreementId,
            walletType!,
            controllerContractId: controllerContractAddress,
            encodedOfferData: cancelTxCalldata,
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
            cancelMarketplaceOfferSignature,
            config.chainId,
            controllerContractAddress,
            signatureData,
            connectedWallet,
            wc,
            wcSession!,
            walletType!,
            encodedOfferData: cancelTxCalldata);
      }

      var txnReceipt =
          await getTxnReceipt(getRPCUrlFromChainId(config.chainId), txnHash);
      if (txnReceipt?.status) {
        ref
            .read(chipSignatureDataProvider.notifier)
            .updateHasBeenUsedInSmartContract(true);
        await cancelOfferBackendRequest(offer.offerHash);
        sendAnalyticsTrace(
            userSession.sessionId, txnHash, "TOKEN_OFFER_CANCEL_SUCCESS",
            tags: {
              'connectedWallet': ref.read(userAddressProvider).hex,
              'chipWallet': convertTokenIdToEthereumAddress(
                  ref.read(chipInfoProvider).tokenId),
            });

        ScaffoldMessenger.of(context).showSnackBar(
          returnSnackBarWidget(
              context.loc.successHeadingSnackbar, 'Offer cancelled', 'success'),
        );

        try {
          await Future.delayed(const Duration(seconds: 2));

          //refresh providers for ownerchip check on ResultScreen
          await ref.refresh(nftOwnerProvider.future);
          await ref.refresh(creatorDataProvider.future);
          await ref.refresh(voucherContractAndTwinNftOwnerProvider.future);
          await ref.refresh(activeOffersProvider.future);
        } catch (e) {
          print(e);
          Sentry.captureException(e);
        }

        setState(() {
          isRotating = false;
          loadingSvgPath = "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/mint.svg";
          loadingText = context.loc.offerCanceled;
        });

        setState(() {
          isLoading = false;
        });
      } else {
        throw Exception('Error cancelling sale of token.');
      }
    } catch (e, s) {
      Sentry.captureException(e);
      setState(() {
        isLoading = false;
      });
      sendAnalyticsTrace(
          userSession.sessionId, e.toString(), "TOKEN_OFFER_CANCEL_ERROR",
          tags: {
            'connectedWallet': ref.read(userAddressProvider).hex,
            'chipWallet': convertTokenIdToEthereumAddress(
                ref.read(chipInfoProvider).tokenId),
          });
      ScaffoldMessenger.of(context).showSnackBar(
        returnSnackBarWidget(context.loc.errorHeadingSnackBar,
            context.loc.errorCancellingSale, 'error'),
      );
    }
  }

  Future<void> redeemTwinToken(Web3App? wc, BigInt tokenId,
      SignatureData signatureData, EthereumAddress connectedWallet) async {
    final UserSession userSession = ref.read(userSessionProvider)!;
    final wcSession = ref.read(wcSessionProvider);
    final walletType = ref.read(walletTypeProvider);
    final TokenChainAndCollection config =
        await ref.watch(findTokenProvider(tokenId).future);
    try {
      setState(() {
        isLoading = true;
        loadingText = context.loc.redeemingtoken;
        isRotating = true;
        loadingSvgPath =
            '${dotenv.get('IMAGE_ASSETS_BASE_URL')}/chip_dark_blue.svg';
      });

      final List response =
          await checkMetaTx(config.collectionId, redeemItemFunctionSignature);
      final bool canUseGasStation = response[0];
      final metaTxAgreementId = response[1];

      final EthereumAddress controllerContractAddress = EthereumAddress.fromHex(
          chainConfig[config.chainId]!.controllerContract);

      final List<Purchase> unredeemedVoucherNfts =
          await ref.watch(unredeemedVoucherNftsProvider.future);
      final String offerHash = unredeemedVoucherNfts.first.offer.offerHash;
      String txnHash;
      if (canUseGasStation) {
        txnHash = await makeAndSendGaslessTx(
            ref,
            ScaffoldKey.getScaffoldKey('UserScanResultsScreen').currentContext!,
            redeemItemFunctionSignature,
            config.chainId,
            config.collectionId,
            signatureData,
            connectedWallet,
            wc,
            wcSession,
            metaTxAgreementId,
            walletType!,
            controllerContractId: controllerContractAddress,
            offerHash: offerHash,
            toggleLoading: toggleLoading);
      } else {
        if (userSession.isOwnerCard) {
          throw 'Gas station needed for TX with OwnerCard.';
        }
        if (wc == null) {
          throw 'No wallet connected. Please connect with MetaMask or similar wallet.';
        }
        txnHash = await makeAndSendNormalTx(
            ref,
            redeemItemFunctionSignature,
            config.chainId,
            controllerContractAddress,
            signatureData,
            connectedWallet,
            wc,
            wcSession!,
            walletType!,
            offerHash: offerHash);
      }

      var txnReceipt =
          await getTxnReceipt(getRPCUrlFromChainId(config.chainId), txnHash);
      if (txnReceipt?.status) {
        sendAnalyticsTrace(
            userSession.sessionId, txnHash, "TOKEN_REDEMPTION_SUCCESS",
            tags: {
              'connectedWallet': ref.read(userAddressProvider).hex,
              'chipWallet': convertTokenIdToEthereumAddress(
                  ref.read(chipInfoProvider).tokenId),
            });

        ScaffoldMessenger.of(context).showSnackBar(
          returnSnackBarWidget(context.loc.successHeadingSnackbar,
              context.loc.tokenRedeemed, 'success'),
        );

        try {
          await Future.delayed(const Duration(seconds: 2));

          //refresh providers for ownerchip check on ResultScreen
          await ref.refresh(nftOwnerProvider.future);
          await ref.refresh(creatorDataProvider.future);
          await ref.refresh(voucherContractAndTwinNftOwnerProvider.future);
        } catch (e) {
          print(e);
          Sentry.captureException(e);
        }

        setState(() {
          isRotating = false;
          loadingSvgPath = "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/mint.svg";
          loadingText = context.loc.tokenRedeemed;
        });

        setState(() {
          isLoading = false;
        });
      } else {
        throw Exception(context.loc.errorRedeemingToken);
      }
    } catch (e, s) {
      Sentry.captureException(e);
      setState(() {
        isLoading = false;
      });
      sendAnalyticsTrace(
          userSession.sessionId, e.toString(), "TOKEN_REDEMPTION_ERROR",
          tags: {
            'connectedWallet': ref.read(userAddressProvider).hex,
            'chipWallet': convertTokenIdToEthereumAddress(
                ref.read(chipInfoProvider).tokenId),
          });
      ScaffoldMessenger.of(context).showSnackBar(
        returnSnackBarWidget(context.loc.errorHeadingSnackBar,
            context.loc.errorRedeemingToken, 'error'),
      );
    }
  }

  Future<void> launchWallet() async {
    await launchUrlString('wc:', mode: LaunchMode.externalApplication);
  }

  Future<dynamic> fromCancelable(Future<dynamic> future) async {
    cancellableOperation?.cancel();
    cancellableOperation =
        CancelableOperation.fromFuture(future, onCancel: () {});
    return cancellableOperation;
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Uri> raribleUrl = ref.watch(raribleUrlProvider);
    final ChipInfoModel chipInfo = ref.watch(chipInfoProvider);
    final activeOffers = ref.watch(activeOffersProvider);
    final AsyncValue<String> nftImageUri =
        ref.watch(nftImageProvider(chipInfo.tokenId));
    final AsyncValue<Map<String, dynamic>> nftMetadata =
        ref.watch(nftMetadataProvider(chipInfo.tokenId));
    final AsyncValue<EthereumAddress> nftOwner = ref.watch(nftOwnerProvider);
    final AsyncValue<EthereumAddress> approval = ref.watch(nftApprovalProvider);
    final AsyncValue<TokenChainAndCollection> tokenInfo =
        ref.watch(findTokenProvider(chipInfo.tokenId));
    final AsyncValue<BlockchainCollectionList> relevantCollections =
        ref.watch(findAllMinterRolesProvider);
    final EthereumAddress connectedWallet = ref.watch(userAddressProvider);
    final UserSession? userSession = ref.watch(userSessionProvider);
    final SignatureData signatureData = ref.watch(chipSignatureDataProvider);
    final wc = ref.watch(wcProvider);
    final AsyncValue<CreatorData> creatorData = ref.watch(creatorDataProvider);
    final AsyncValue<EthereumAddress?> voucherContractAddress =
        ref.watch(voucherContractProvider);
    final AsyncValue<EthereumAddress?> vouchertokenOwner =
        ref.watch(voucherTokenOwnerProvider);
    final AsyncValue<List<Purchase>> unredeemedVoucherNfts =
        ref.watch(unredeemedVoucherNftsProvider);
    final AsyncValue<EthereumAddress> lastSellerAddress =
        ref.watch(lastSellerAddressProvider);

    Sentry.configureScope(
      (scope) => scope.setUser(SentryUser(id: connectedWallet.toString())),
    );

    return CustomOverlay(
        show: isLoading,
        content: SpinningLoadingSvg(
          onPressed: () {
            cancellableOperation?.cancel();
            setState(() {
              isLoading = false;
            });
            Navigator.pushNamedAndRemoveUntil(
                context, HomeScreen.routeName, (route) => false);
          },
          loadingText: loadingText,
          rotateIcon: isRotating,
          svgPath: loadingSvgPath,
        ),
        child: Scaffold(
            key: ScaffoldKey.getScaffoldKey('UserScanResultsScreen'),
            extendBodyBehindAppBar: true,
            appBar: CustomAppBar(
              text: context.loc.tapResults,
            ),
            body: ScreenBodyLayout(children: [
              Stack(
                alignment: Alignment.topCenter,
                children: [
                  CustomCard(
                      margin: const EdgeInsets.only(top: 70),
                      width: double.infinity,
                      children: [
                        const SizedBox(height: 100),
                        nftMetadata.when(
                          loading: () => Text(context.loc.loading,
                              style: Theme.of(context).textTheme.displayLarge!),
                          data: (nftMetadataData) => nftMetadataData['name'] !=
                                  null
                              ? GestureDetector(
                                  onTap: () {
                                    Navigator.of(context)
                                        .pushNamed(NFTDetailsScreen.routeName);
                                  },
                                  child: Text(nftMetadataData['name'],
                                      style: Theme.of(context)
                                          .textTheme
                                          .displayLarge!))
                              : Container(),
                          error: (error, stackTrace) {
                            print(error);
                            if (error == 'Token does not exist.') {
                              return Container();
                            } else {
                              return RefreshMetadataButton();
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        //AUTHENTICITY CHECK
                        CustomCard(
                            color: CustomColors(dotenv.get('APP_ID'))
                                .secondaryColor,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(context.loc.authenticityCheck,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium),

                                  //AUTHENTICITY CHECK ICON
                                  tokenInfo.when(
                                    data: ((tokenInfoData) => tokenInfoData
                                                .collectionId ==
                                            zeroAddress
                                        ? SvgPicture.asset(
                                            "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/alert_cross.svg")
                                        : SvgPicture.asset(
                                            "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/check.svg")),
                                    error: (e, s) => SvgPicture.asset(
                                        "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/triangle_small.svg"),
                                    loading: () =>
                                        const CircularProgressIndicator(),
                                  )
                                ],
                              ),
                              const SizedBox(height: 15),

                              //AUTHENTICITY CHECK BODY
                              Align(
                                  alignment: Alignment.centerLeft,
                                  child: tokenInfo.when(
                                      data: (tokenInfoData) =>
                                          tokenInfoData.collectionId ==
                                                  zeroAddress
                                              // NFT DOES NOT EXIST
                                              ? Text(
                                                  context.loc
                                                      .authenticityNftNotFound,
                                                  textAlign: TextAlign.left,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium)
                                              // NFT EXISTS
                                              : creatorData.when(
                                                  data: (creatorDataData) =>
                                                      CreatorDataBoxContent(
                                                          creatorData:
                                                              creatorDataData),
                                                  loading: () =>
                                                      const CircularProgressIndicator(),
                                                  error: (e, s) => Text(
                                                      context.loc
                                                          .authenticityNftFound,
                                                      textAlign: TextAlign.left,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium),
                                                ),
                                      error: (e, s) => Text(
                                          context.loc.authenticityNftNotFound,
                                          textAlign: TextAlign.left,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium),
                                      loading: () =>
                                          const CircularProgressIndicator())),
                            ]),
                        const SizedBox(height: 15),

                        //OWNERSHIP CHECK
                        CustomCard(
                            color: CustomColors(dotenv.get('APP_ID'))
                                .secondaryColor,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(context.loc.ownershipCheck,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium),

                                  //OWNERSHIP CHECK ICON
                                  nftOwner.when(
                                    data: ((nftOwnerData) => userSession == null
                                        ?
                                        //NFT owner exists and wallet is NOT connected
                                        SvgPicture.asset(
                                            "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/triangle_small.svg")
                                        : connectedWallet == nftOwnerData
                                            ?
                                            //NFT owner exists and wallet is connected and wallet is owner
                                            approval.value == zeroAddress
                                                ? SvgPicture.asset(
                                                    "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/check.svg")
                                                // NFT owner has approved another wallet
                                                : SvgPicture.asset(
                                                    "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/triangle_small.svg")

                                            //NFT owner exists and wallet is connected and wallet is NOT owner
                                            : SvgPicture.asset(
                                                "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/alert_cross.svg")),
                                    error: (e, s) => SvgPicture.asset(
                                        "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/triangle_small.svg"),
                                    loading: () =>
                                        const CircularProgressIndicator(),
                                  )
                                ],
                              ),
                              const SizedBox(height: 15),

                              //OWNERSHIP CHECK BODY
                              Align(
                                  alignment: Alignment.centerLeft,
                                  child: activeOffers.when(
                                    data: (activeOffersData) {
                                      if (activeOffersData.isEmpty) {
                                        //TOKEN IS NOT FOR SALE
                                        return nftOwner.when(
                                            data: (nftOwnerData) {
                                              if (connectedWallet ==
                                                      zeroAddress ||
                                                  userSession == null) {
                                                //USER IS NOT CONNECTED
                                                return Column(
                                                  children: [
                                                    Align(
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        child: Text(
                                                            context.loc
                                                                .noWalletConnected,
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .bodyMedium)),
                                                    const SizedBox(height: 10),
                                                    CustomRoundedButton(
                                                        text: context
                                                            .loc.connectWallet,
                                                        onPressed: (() => {
                                                              walletPopupBuilder(
                                                                  context, ref)
                                                            }))
                                                  ],
                                                );
                                              } else {
                                                //USER IS CONNECTED
                                                if (connectedWallet ==
                                                    nftOwnerData) {
                                                  //USER IS OWNER
                                                  return approval.when(
                                                      data: (approvalData) {
                                                        if (approvalData ==
                                                            zeroAddress) {
                                                          //TOKEN IS NOT APPROVED / NOT READY TO BE CLAIMED BY NEW OWNER
                                                          return relevantCollections
                                                              .when(
                                                                  data:
                                                                      (relevantCollectionsData) {
                                                                    late Collection
                                                                        collection;
                                                                    if (relevantCollectionsData.collections[tokenInfo
                                                                            .value!
                                                                            .chainId] !=
                                                                        null) {
                                                                      // USER HAS MINTERROLE FOR SOME COLLECTION
                                                                      collection = relevantCollectionsData.collections[tokenInfo.value!.chainId]!.firstWhere(
                                                                          (element) =>
                                                                              element.id ==
                                                                              tokenInfo
                                                                                  .value!.collectionId,
                                                                          orElse: () => Collection(
                                                                              zeroAddress,
                                                                              '',
                                                                              hasMinterRole: false));
                                                                    } else {
                                                                      //USER DOES NOT HAVE MINTERROLE ANYWHERE
                                                                      collection = Collection(
                                                                          zeroAddress,
                                                                          '',
                                                                          hasMinterRole:
                                                                              false);
                                                                    }
                                                                    if (collection
                                                                            .hasMinterRole! &&
                                                                        collection.id ==
                                                                            tokenInfo.value!.collectionId) {
                                                                      // USER HAS MINTER ROLE FOR THIS TOKENS COLLECTION
                                                                      return Column(
                                                                        children: [
                                                                          Align(
                                                                              alignment: Alignment.centerLeft,
                                                                              child: Text(context.loc.youAreNFTOwner, textAlign: TextAlign.left, style: Theme.of(context).textTheme.bodyMedium)),
                                                                          const SizedBox(
                                                                              height: 10),
                                                                          CustomOutlinedButton(
                                                                              width: double
                                                                                  .infinity,
                                                                              buttonText: context
                                                                                  .loc.burnToken,
                                                                              onPressed: (() => {
                                                                                    fromCancelable(burnToken(wc, chipInfo.tokenId, signatureData, connectedWallet))
                                                                                  }))
                                                                        ],
                                                                      );
                                                                    } else {
                                                                      // USER DOES NOT HAVE MINTER ROLE FOR THIS TOKENS COLLECTION
                                                                      return Column(
                                                                        children: [
                                                                          Align(
                                                                              alignment: Alignment.centerLeft,
                                                                              child: Text(context.loc.youAreNFTOwner, textAlign: TextAlign.left, style: Theme.of(context).textTheme.bodyMedium)),
                                                                        ],
                                                                      );
                                                                    }
                                                                  },
                                                                  error: (e,
                                                                          s) =>
                                                                      Container(),
                                                                  loading: () =>
                                                                      Container());
                                                        } else {
                                                          //TOKEN IS APPROVED / IS READY TO BE CLAIMED BY NEW OWNER
                                                          return Column(
                                                            children: [
                                                              Text(
                                                                  context.loc
                                                                          .tokenWasTransferred +
                                                                      getEthAddressSubstring(
                                                                          approval
                                                                              .value!) +
                                                                      context.loc
                                                                          .tokenNotYetClaimed,
                                                                  textAlign:
                                                                      TextAlign
                                                                          .left,
                                                                  style: Theme.of(
                                                                          context)
                                                                      .textTheme
                                                                      .bodyMedium),
                                                            ],
                                                          );
                                                        }
                                                      },
                                                      loading: () =>
                                                          Container(),
                                                      error: (e, s) =>
                                                          Container());
                                                } else {
                                                  //USER IS NOT OWNER
                                                  return approval.when(
                                                      data: (approvalData) {
                                                        if (approvalData ==
                                                            zeroAddress) {
                                                          //TOKEN IS NOT APPROVED / NOT READY TO BE CLAIMED
                                                          return voucherContractAddress
                                                              .when(
                                                            data:
                                                                (voucherContractData) {
                                                              // VOUCHER CONTRACT EXISTS
                                                              return vouchertokenOwner
                                                                  .when(
                                                                      data:
                                                                          (voucherTokenOwnerData) {
                                                                        if (voucherTokenOwnerData ==
                                                                                connectedWallet &&
                                                                            voucherContractData !=
                                                                                null) {
                                                                          //USER IS VOUCHER OWNER AND CAN REDEEM TWIN
                                                                          return Column(
                                                                              children: [
                                                                                Text(context.loc.youAreTheNewOwner, textAlign: TextAlign.left, style: Theme.of(context).textTheme.bodyMedium),
                                                                                const SizedBox(height: 15),
                                                                                CustomRoundedButton(
                                                                                    width: double.infinity,
                                                                                    text: context.loc.redeemToken,
                                                                                    onPressed: (() => {
                                                                                          fromCancelable(redeemTwinToken(wc, chipInfo.tokenId, signatureData, connectedWallet))
                                                                                        })),
                                                                              ]);
                                                                        } else {
                                                                          //USER IS NOT VOUCHER OWNER
                                                                          return tokenInfo.when(
                                                                              data: (tokenInfoData) {
                                                                                final EthereumAddress controllerContractAddress = EthereumAddress.fromHex(chainConfig[tokenInfoData.chainId]!.controllerContract);
                                                                                if (voucherTokenOwnerData == controllerContractAddress && nftOwnerData == controllerContractAddress && activeOffersData.isEmpty) {
                                                                                  //ERROR HAPPENED WHEN TOKEN WAS OFFERED; NO OFFER IN BACKEND
                                                                                  return lastSellerAddress.when(
                                                                                      data: (lastSellerData) {
                                                                                        if (lastSellerData == connectedWallet) {
                                                                                          return Column(
                                                                                            children: [
                                                                                              Text(context.loc.errorWhenOffering, textAlign: TextAlign.left, style: Theme.of(context).textTheme.bodyMedium),
                                                                                              const SizedBox(height: 15),
                                                                                              CustomRoundedButton(
                                                                                                width: double.infinity,
                                                                                                text: context.loc.recoverToken,
                                                                                                onPressed: (() => {
                                                                                                      fromCancelable(recoverToken(wc, chipInfo.tokenId, signatureData, connectedWallet))
                                                                                                    }),
                                                                                              )
                                                                                            ],
                                                                                          );
                                                                                        } else {
                                                                                          return Column(
                                                                                            children: [
                                                                                              Text(context.loc.youAreNotNftOwner, textAlign: TextAlign.left, style: Theme.of(context).textTheme.bodyMedium),
                                                                                            ],
                                                                                          );
                                                                                        }
                                                                                      },
                                                                                      error: (e, s) => Container(),
                                                                                      loading: () => Container());
                                                                                } else {
                                                                                  return FutureBuilder<List>(
                                                                                      future: getUnredeemedPurchases(chipInfo.tokenId),
                                                                                      builder: (BuildContext context, AsyncSnapshot<List> snapshot) {
                                                                                        if (snapshot.hasData) {
                                                                                          if (snapshot.data!.isNotEmpty && EthereumAddress.fromHex(snapshot.data![0].offer.sellerAddress) == connectedWallet) {
                                                                                            //USER IS SELLER AND ITEM HAS NOT BEEN REDEEMED YET
                                                                                            return Column(children: [
                                                                                              Text(context.loc.thisItemHasBeenSold, textAlign: TextAlign.left, style: Theme.of(context).textTheme.bodyMedium),
                                                                                            ]);
                                                                                          } else {
                                                                                            //USER IS NOT SELLER AND ITEM HAS NOT BEEN REDEEMED YET
                                                                                            return Text(context.loc.youAreNotNftOwner, textAlign: TextAlign.left, style: Theme.of(context).textTheme.bodyMedium);
                                                                                          }
                                                                                        } else if (snapshot.hasError) {
                                                                                          return Text(context.loc.youAreNotNftOwner, textAlign: TextAlign.left, style: Theme.of(context).textTheme.bodyMedium);
                                                                                        } else {
                                                                                          return const CircularProgressIndicator();
                                                                                        }
                                                                                      });
                                                                                }
                                                                              },
                                                                              error: (e, s) => Container(),
                                                                              loading: () => Container());
                                                                        }
                                                                      },
                                                                      error: (e, s) => Text(
                                                                          context
                                                                              .loc
                                                                              .youAreNotNftOwner,
                                                                          textAlign: TextAlign
                                                                              .left,
                                                                          style: Theme.of(context)
                                                                              .textTheme
                                                                              .bodyMedium),
                                                                      loading: () =>
                                                                          Container());
                                                            },
                                                            loading: () =>
                                                                Container(),
                                                            error: (e, s) {
                                                              return Column(
                                                                children: [
                                                                  Align(
                                                                      alignment:
                                                                          Alignment
                                                                              .centerLeft,
                                                                      child: Text(
                                                                          context
                                                                              .loc
                                                                              .youAreNotNftOwner,
                                                                          textAlign: TextAlign
                                                                              .center,
                                                                          style: Theme.of(context)
                                                                              .textTheme
                                                                              .bodyMedium)),
                                                                ],
                                                              );
                                                            },
                                                          );
                                                        } else {
                                                          //TOKEN IS APPROVED / IS READY TO BE CLAIMED
                                                          return approval.when(
                                                              data:
                                                                  (approvalData) {
                                                                if (approvalData ==
                                                                    connectedWallet) {
                                                                  //USER IS APPROVED TO CLAIM
                                                                  return Column(
                                                                    children: [
                                                                      Align(
                                                                          alignment: Alignment
                                                                              .centerLeft,
                                                                          child: Text(
                                                                              context.loc.youAreTheNewOwner,
                                                                              textAlign: TextAlign.left,
                                                                              style: Theme.of(context).textTheme.bodyMedium)),
                                                                      const SizedBox(
                                                                          height:
                                                                              10),
                                                                      CustomRoundedButton(
                                                                          width: double
                                                                              .infinity,
                                                                          text: context
                                                                              .loc
                                                                              .claimOwnership,
                                                                          onPressed: (() =>
                                                                              {
                                                                                fromCancelable(claimToken(wc, chipInfo.tokenId, signatureData, connectedWallet))
                                                                              }))
                                                                    ],
                                                                  );
                                                                } else {
                                                                  //USER IS NOT APPROVED TO CLAIM
                                                                  return Text(
                                                                      context
                                                                          .loc
                                                                          .youAreNotNftOwner,
                                                                      textAlign:
                                                                          TextAlign
                                                                              .left,
                                                                      style: Theme.of(
                                                                              context)
                                                                          .textTheme
                                                                          .bodyMedium);
                                                                }
                                                              },
                                                              loading: () =>
                                                                  Container(),
                                                              error: (e, s) =>
                                                                  Container());
                                                        }
                                                      },
                                                      loading: () =>
                                                          Container(),
                                                      error: (e, s) =>
                                                          Container());
                                                }
                                              }
                                            },
                                            loading: () => Container(),
                                            error: (e, s) => Text(
                                                context.loc.youAreNotNftOwner,
                                                textAlign: TextAlign.left,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium));
                                      } else {
                                        //TOKEN IS FOR SALE
                                        if (activeOffersData.isNotEmpty &&
                                            EthereumAddress.fromHex(
                                                    activeOffersData[0]
                                                        .sellerAddress) ==
                                                connectedWallet) {
                                          //USER IS SELLER
                                          return Column(
                                            children: [
                                              Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                      context.loc
                                                          .tokenCurrentlyOfferedForSale,
                                                      textAlign: TextAlign.left,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium)),
                                              const SizedBox(height: 10),
                                              CustomRoundedButton(
                                                  text: context.loc.cancelOffer,
                                                  onPressed: () {
                                                    fromCancelable(cancelOffer(
                                                        wc,
                                                        chipInfo.tokenId,
                                                        signatureData,
                                                        connectedWallet));
                                                  })
                                            ],
                                          );
                                        } else {
                                          //USER IS NOT SELLER
                                          return Column(
                                            children: [
                                              Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                      context.loc
                                                          .itemAvailableForSale,
                                                      textAlign: TextAlign.left,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium)),
                                              const SizedBox(height: 10),
                                              CustomRoundedButton(
                                                text: context.loc.buyOnRarible,
                                                onPressed: () => {
                                                  launchUrl(
                                                      raribleUrl.asData!.value,
                                                      mode: LaunchMode
                                                          .externalApplication)
                                                },
                                              )
                                            ],
                                          );
                                        }
                                      }
                                    },
                                    loading: () => Container(),
                                    error: (e, s) => Container(),
                                  ))
                            ]),
                      ]),
                  GestureDetector(
                      onTap: () {
                        Navigator.of(context)
                            .pushNamed(NFTDetailsScreen.routeName);
                      },
                      child: nftImageUri.when(
                        loading: () => const CustomImage(
                          width: 130,
                          loading: true,
                        ),
                        error: (e, s) => const CustomImage(
                          width: 130,
                          loading: false,
                        ),
                        data: (nftImageUriData) => CustomImage(
                          width: 130,
                          loading: false,
                          imagePath: nftImageUriData,
                        ),
                      )),
                ],
              ),
              const SizedBox(height: 20),

              //if token does not exists
              tokenInfo.when(
                  data: (tokenInfoData) =>
                      tokenInfoData.collectionId == zeroAddress &&
                              connectedWallet != zeroAddress &&
                              userSession != null &&
                              relevantCollections.value!.collections.isNotEmpty
                          ? CustomRoundedButton(
                              text: context.loc.initializeChip,
                              onPressed: () async {
                                if (mounted) {
                                  await initializeItem(ref, context);
                                }
                              })
                          : tokenInfoData.collectionId == zeroAddress
                              ? Container()
                              : CustomRoundedButton(
                                  text: context.loc.viewNftDetails,
                                  onPressed: () {
                                    Navigator.of(context)
                                        .pushNamed(NFTDetailsScreen.routeName);
                                  }),
                  error: (e, s) => Container(),
                  loading: () => Container()),

              //show chip address in light grey text
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${context.loc.chipAddress}: ${getEthAddressSubstring(chipInfo.chipEthereumAddress)}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall!
                        .copyWith(color: Color.fromARGB(255, 143, 143, 143)),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  IconButton(
                      color: Color.fromARGB(255, 143, 143, 143),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 25,
                      onPressed: () {
                        Clipboard.setData(ClipboardData(
                            text: chipInfo.chipEthereumAddress.hex));
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(context.loc.addressCopied)));
                      },
                      icon: const Icon(Icons.copy)),
                ],
              )
            ])));
  }
}
