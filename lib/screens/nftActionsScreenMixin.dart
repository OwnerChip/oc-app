//import packages
import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:ownerchip_whitelabel/domain/phygitalTradeTypes.dart';
import 'package:ownerchip_whitelabel/services/backend/app/backendApp.dart';
import 'package:ownerchip_whitelabel/services/backend/attachments/backendAttachments.dart';
import 'package:ownerchip_whitelabel/services/backend/metaTx/backendMetaTx.dart';
import 'package:ownerchip_whitelabel/services/backend/offer/backendOffer.dart';
import 'package:ownerchip_whitelabel/services/providers/collectionsData.dart';
import 'package:ownerchip_whitelabel/services/providers/purchasesData.dart';
import 'package:ownerchip_whitelabel/services/rarible.services.dart';
import 'package:ownerchip_whitelabel/services/wallet.services.dart';
import 'package:ownerchip_whitelabel/services/web3.services.dart';
import 'package:ownerchip_whitelabel/utils/globals.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:web3dart/web3dart.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/services/providers/chipData.dart';
import 'package:ownerchip_whitelabel/services/providers/nftData.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';

//import widgets

//import misc
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/config/chains.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';

mixin NftActionScreenMixin<T extends ConsumerStatefulWidget>
    implements ConsumerState<T> {
  CancelableOperation? cancellableOperation;

  bool isLoading = false;
  bool isRotating = true;
  String loadingSvgPath =
      '${dotenv.get('IMAGE_ASSETS_BASE_URL')}/chip_dark_blue.svg';
  String loadingText = '';

  String pageKey = 'NftActionsScreen';

  Future<dynamic> fromCancelable(Future<dynamic> future) async {
    cancellableOperation?.cancel();
    cancellableOperation =
        CancelableOperation.fromFuture(future, onCancel: () {});
    return cancellableOperation;
  }

  Future<void> toggleLoading() async {
    setState(() {
      isLoading = !isLoading;
    });
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

      final List response = await BackendMetaTx.checkMetaTx(
          config.collectionId, recoverTokenFunctionSignature);
      final bool canUseGasStation = response[0];
      final metaTxAgreementId = response[1];

      final EthereumAddress controllerContractAddress = EthereumAddress.fromHex(
          chainConfig[config.chainId]!.controllerContract);

      String txnHash = "";

      Future<String> normalTx() async {
        return await makeAndSendNormalTx(
            context,
            ref,
            recoverTokenFunctionSignature,
            config.chainId,
            controllerContractAddress,
            signatureData,
            connectedWallet,
            wc!,
            wcSession,
            walletType!);
      }

      try {
        if (canUseGasStation) {
          txnHash = await callFunctionWithFallback(
              function: () {
                return makeAndSendGaslessTx(
                    ref,
                    ScaffoldKey.getScaffoldKey(pageKey).currentContext!,
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
        Sentry.captureException(e, stackTrace: st);
        talker.error(e, st);
      }

      talker.info('txnHash: $txnHash');

      var txnReceipt =
          await getTxnReceipt(getRPCUrlFromChainId(config.chainId), txnHash);
      if (txnReceipt?.status == true) {
        ref
            .read(chipSignatureDataProvider.notifier)
            .updateHasBeenUsedInSmartContract(true);
        BackendApp.sendAnalyticsTrace(
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
      BackendApp.sendAnalyticsTrace(
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

  Future<void> burnToken(
    Web3App? wc,
    BigInt tokenId,
    SignatureData signatureData,
    EthereumAddress connectedWallet, {
    VoidCallback? onSuccess,
  }) async {
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

      BackendApp.sendAnalyticsTrace(sessionId.toString(), "", "BURN_STARTED",
          tags: {
            'connectedWallet': connectedWallet.hex,
            'chipWallet': convertTokenIdToEthereumAddress(
                ref.read(chipInfoProvider).tokenId)
          });

      final List response = await BackendMetaTx.checkMetaTx(
          config.collectionId, burnFunctionSignature);
      final bool canUseGasStation = response[0];
      final metaTxAgreementId = response[1];

      String txnHash = "";

      Future<void> normalNx() async {
        txnHash = await makeAndSendNormalTx(
            context,
            ref,
            burnFunctionSignature,
            config.chainId,
            config.collectionId,
            signatureData,
            connectedWallet,
            wc!,
            wcSession,
            walletType!);
      }

      try {
        if (canUseGasStation) {
          txnHash = await makeAndSendGaslessTx(
              ref,
              ScaffoldKey.getScaffoldKey(pageKey).currentContext!,
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
          if (wc == null) {
            throw 'Please connect with MetaMask or similar wallet.';
          }
          await normalNx();
        }
      } catch (e, st) {
        Sentry.captureException(e, stackTrace: st);
        talker.error(e, st);
        await normalNx();
      }

      talker.info('txnHash: $txnHash');

      var txnReceipt =
          await getTxnReceipt(getRPCUrlFromChainId(config.chainId), txnHash);
      if (txnReceipt?.status == true) {
        //this means burn succeeded
        setState(() {
          isRotating = false;
          loadingSvgPath = "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/burn.svg";
          loadingText = context.loc.burnedSuccess;
        });

        BackendAttachments.deleteAllAttachments(userSession, connectedWallet,
            config.chainId, config.collectionId, tokenId, signatureData);
        // send status to analytics
        burnProcess.finish();
        BackendApp.sendAnalyticsTrace(sessionId, txnHash, "BURN_SUCCESS",
            tags: {
              'connectedWallet': connectedWallet.hex,
              'chipWallet': convertTokenIdToEthereumAddress(
                  ref.read(chipInfoProvider).tokenId)
            });

        await Future.delayed(const Duration(seconds: 2));

        onSuccess?.call();

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
      BackendApp.sendAnalyticsTrace(sessionId, "", "BURN_ERROR", tags: {
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

      final List response = await BackendMetaTx.checkMetaTx(
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

      String txnHash = "";

      Future<String> normalTx() async {
        return await makeAndSendNormalTx(
            context,
            ref,
            cancelMarketplaceOfferSignature,
            config.chainId,
            controllerContractAddress,
            signatureData,
            connectedWallet,
            wc!,
            wcSession,
            walletType!,
            encodedOfferData: cancelTxCalldata);
      }

      try {
        if (canUseGasStation) {
          txnHash = await callFunctionWithFallback(
            function: () {
              return makeAndSendGaslessTx(
                  ref,
                  ScaffoldKey.getScaffoldKey(pageKey).currentContext!,
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
            },
            fallback: normalTx,
            predicate: gaslessTransactionFallbackPredicate,
          );
        } else {
          if (wc == null) {
            throw 'Please connect with MetaMask or similar wallet.';
          }

          txnHash = await normalTx();
        }
      } catch (e) {
        Sentry.captureException(e);
        talker.error(e);
      }

      talker.info('txnHash: $txnHash');

      var txnReceipt =
          await getTxnReceipt(getRPCUrlFromChainId(config.chainId), txnHash);
      if (txnReceipt?.status == true) {
        ref
            .read(chipSignatureDataProvider.notifier)
            .updateHasBeenUsedInSmartContract(true);
        await BackendOffer.cancelOfferBackendRequest(
          offer.offerHash,
        );
        BackendApp.sendAnalyticsTrace(
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
      talker.error(e, s);
      BackendApp.sendAnalyticsTrace(
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

      BackendApp.sendAnalyticsTrace(sessionId.toString(), "", "CLAIM_STARTED",
          tags: {
            'connectedWallet': connectedWallet.hex,
            'chipWallet': convertTokenIdToEthereumAddress(
                ref.read(chipInfoProvider).tokenId)
          });

      final List response = await BackendMetaTx.checkMetaTx(
          config.collectionId, transferFromFunctionSignature);
      final bool canUseGasStation = response[0];
      final metaTxAgreementId = response[1];

      String txnHash = "";

      Future<String> normalTx() async {
        return await makeAndSendNormalTx(
            context,
            ref,
            transferFromFunctionSignature,
            config.chainId,
            config.collectionId,
            signatureData,
            connectedWallet,
            wc!,
            wcSession,
            walletType!);
      }

      try {
        if (canUseGasStation) {
          txnHash = await callFunctionWithFallback(
              function: () {
                return makeAndSendGaslessTx(
                    ref,
                    ScaffoldKey.getScaffoldKey(pageKey).currentContext!,
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
              },
              fallback: normalTx);
        } else {
          if (wc == null) {
            throw 'Please connect with MetaMask or similar wallet.';
          }
          txnHash = await normalTx();
        }
      } catch (e, st) {
        Sentry.captureException(e, stackTrace: st);
        talker.error(e, st);
        talker.info("error sending gasless tx, trying normal tx");
      }

      var txnReceipt =
          await getTxnReceipt(getRPCUrlFromChainId(config.chainId), txnHash);
      if (txnReceipt?.status == true) {
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
        BackendApp.sendAnalyticsTrace(sessionId, txnHash, "CLAIM_SUCCESS",
            tags: {
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
      BackendApp.sendAnalyticsTrace(sessionId, "", "CLAIM_ERROR", tags: {
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

      final List response = await BackendMetaTx.checkMetaTx(
          config.collectionId, redeemItemFunctionSignature);
      final bool canUseGasStation = response[0];
      final metaTxAgreementId = response[1];

      final EthereumAddress controllerContractAddress = EthereumAddress.fromHex(
          chainConfig[config.chainId]!.controllerContract);

      final List<Purchase> unredeemedVoucherNfts =
          await ref.watch(unredeemedVoucherNftsProvider.future);
      final String offerHash = unredeemedVoucherNfts
          .firstWhere((e) => e.token.id == tokenId)
          .offer
          .offerHash;

      String txnHash = "";

      Future<String> normalTx() async {
        return await makeAndSendNormalTx(
            context,
            ref,
            redeemItemFunctionSignature,
            config.chainId,
            controllerContractAddress,
            signatureData,
            connectedWallet,
            wc!,
            wcSession,
            walletType!,
            offerHash: offerHash);
      }

      try {
        if (canUseGasStation) {
          txnHash = await callFunctionWithFallback(
            function: () {
              return makeAndSendGaslessTx(
                  ref,
                  ScaffoldKey.getScaffoldKey(pageKey).currentContext!,
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
            },
            fallback: normalTx,
            predicate: gaslessTransactionFallbackPredicate,
          );
        } else {
          if (wc == null) {
            throw 'No wallet connected. Please connect with MetaMask or similar wallet.';
          }
          txnHash = await normalTx();
        }
      } catch (e, st) {
        Sentry.captureException(e, stackTrace: st);
        talker.error(e, st);
      }

      var txnReceipt =
          await getTxnReceipt(getRPCUrlFromChainId(config.chainId), txnHash);
      if (txnReceipt?.status == true) {
        BackendApp.sendAnalyticsTrace(
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
      BackendApp.sendAnalyticsTrace(
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
}
