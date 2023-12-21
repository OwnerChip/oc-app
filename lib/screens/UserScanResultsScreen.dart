//import packages
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ownerchip_whitelabel/config/chains.dart';
import 'package:ownerchip_whitelabel/services/scan.services.dart';
import 'package:ownerchip_whitelabel/utils/globals.dart';
import 'package:ownerchip_whitelabel/widgets/popups/CustomOverlay.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CreatorDataBoxContent.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomOutlinedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/RefreshMetadataButton.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:web3dart/web3dart.dart';
import 'package:sentry/sentry.dart';
import 'package:async/async.dart';

//import services
import 'package:ownerchip_whitelabel/services/wallet.services.dart';
import 'package:ownerchip_whitelabel/services/backend.services.dart';
import 'package:ownerchip_whitelabel/services/web3.services.dart';
import 'package:ownerchip_whitelabel/services/attachments.services.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/services/providers/chipData.dart';
import 'package:ownerchip_whitelabel/services/providers/collectionsData.dart';
import 'package:ownerchip_whitelabel/services/providers/nftData.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';

//import screens
import 'package:ownerchip_whitelabel/screens/NFTDetailsScreen.dart';
import 'package:ownerchip_whitelabel/screens/HomeScreen.dart';
import 'package:ownerchip_whitelabel/screens/TransferScreen.dart';

//import widgets
import 'package:ownerchip_whitelabel/widgets/ui/CustomCard.dart';
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomImage.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomAppBar.dart';
import 'package:ownerchip_whitelabel/widgets/ui/SpinningLoadingSvg.dart';
import 'package:ownerchip_whitelabel/widgets/popups/WalletPopUp.dart';

//import misc
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/utils/navigationArguments.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';

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
    String sessionId = ref.read(userSessionProvider)!.sessionId;
    final TokenChainAndCollection config =
        await ref.watch(findTokenProvider(tokenId).future);
    final burnProcess = Sentry.startTransaction('initBurn()', 'task');
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

        Navigator.pushNamedAndRemoveUntil(
            ScaffoldKey.getScaffoldKey('UserScanResultsScreen').currentContext!,
            HomeScreen.routeName,
            (route) => false);
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
        await Future.delayed(const Duration(seconds: 2));

        // update providers
        await ref.refresh(nftApprovalProvider.future);
        await ref.refresh(nftOwnerProvider.future);

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

  Future<void> cancelOffer(Web3App? wc, BigInt tokenId,
      SignatureData signatureData, EthereumAddress connectedWallet) async {
    final UserSession userSession = ref.read(userSessionProvider)!;
    final wcSession = ref.read(wcSessionProvider);
    final walletType = ref.read(walletTypeProvider);
    String sessionId = ref.read(userSessionProvider)!.sessionId;
    final TokenChainAndCollection config =
        await ref.watch(findTokenProvider(tokenId).future);
    try {
      setState(() {
        isLoading = true;
        loadingText = 'Cancelling offer';
        isRotating = true;
        loadingSvgPath =
            '${dotenv.get('IMAGE_ASSETS_BASE_URL')}/chip_dark_blue.svg';
      });

      final List response =
          await checkMetaTx(config.collectionId, cancelOfferFunctionSignature);
      final bool canUseGasStation = response[0];
      final metaTxAgreementId = response[1];

      final EthereumAddress controllerContractAddress = EthereumAddress.fromHex(
          chainConfig[config.chainId]!.controllerContract);

      //fetch order data from backend
      CreatorData creatorData = await ref.read(creatorDataProvider.future);
      final allOffers =
          creatorData.tokenForWhichCreatorDataWasRequested.activeOffers;
      final offer = allOffers.firstWhere((o) => o.isCancelled == false);

      String txnHash;
      if (canUseGasStation) {
        txnHash = await makeAndSendGaslessTx(
            ref,
            ScaffoldKey.getScaffoldKey('UserScanResultsScreen').currentContext!,
            cancelOfferFunctionSignature,
            config.chainId,
            config.collectionId,
            signatureData,
            connectedWallet,
            wc,
            wcSession,
            metaTxAgreementId,
            walletType!,
            controllerContractId: controllerContractAddress,
            salt: BigInt.from(DateTime.now().millisecondsSinceEpoch),
            encodedOfferData: offer.encodedData,
            endTimestamp: offer.validUntil,
            toggleLoading: toggleLoading);
      } else {
        if (userSession.isOwnerCard) {
          throw 'Gas station needed for TX with OwnerCard.';
        }
        if (wc == null) {
          throw 'Please connect with MetaMask or similar wallet.';
        }
        txnHash = await makeAndSendNormalTx(
          cancelOfferFunctionSignature,
          config.chainId,
          controllerContractAddress,
          signatureData,
          connectedWallet,
          wc,
          wcSession!,
          walletType!,
          salt: BigInt.from(DateTime.now().millisecondsSinceEpoch),
          encodedOfferData: offer.encodedData,
          endTimestamp: offer.validUntil,
        );
      }

      var txnReceipt =
          await getTxnReceipt(getRPCUrlFromChainId(config.chainId), txnHash);
      if (txnReceipt?.status) {
        await cancelOfferBackendRequest(offer.offerHash);

        ScaffoldMessenger.of(context).showSnackBar(
          returnSnackBarWidget(
              context.loc.successHeadingSnackbar, 'Offer cancelled', 'success'),
        );

        await Future.delayed(const Duration(seconds: 2));

        //refresh providers for ownerchip check on ResultScreen
        await ref.refresh(nftOwnerProvider.future);
        await ref.refresh(creatorDataProvider.future);
        await ref.refresh(voucherContractAndTwinNftOwnerProvider.future);

        setState(() {
          isRotating = false;
          loadingSvgPath = "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/mint.svg";
          loadingText = context.loc.offerCanceled;
        });

        //delay two seconds
        await Future.delayed(const Duration(seconds: 2));

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
          await checkMetaTx(config.collectionId, cancelOfferFunctionSignature);
      final bool canUseGasStation = response[0];
      final metaTxAgreementId = response[1];

      final EthereumAddress controllerContractAddress = EthereumAddress.fromHex(
          chainConfig[config.chainId]!.controllerContract);

      //fetch order data from backend
      CreatorData creatorData = await ref.read(creatorDataProvider.future);
      final allOffers =
          creatorData.tokenForWhichCreatorDataWasRequested.activeOffers;
      final offer = allOffers.firstWhere((o) =>
          o.isCancelled ==
          false); //TODO: dont get offer by is cancelled but some isRedeemed or other flag which will be sent from backend
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
            offerHash: offer.offerHash,
            toggleLoading: toggleLoading);
      } else {
        if (userSession.isOwnerCard) {
          throw 'Gas station needed for TX with OwnerCard.';
        }
        if (wc == null) {
          throw 'No wallet connected. Please connect with MetaMask or similar wallet.';
        }
        txnHash = await makeAndSendNormalTx(
            redeemItemFunctionSignature,
            config.chainId,
            controllerContractAddress,
            signatureData,
            connectedWallet,
            wc,
            wcSession!,
            walletType!,
            offerHash: offer.offerHash);
      }

      var txnReceipt =
          await getTxnReceipt(getRPCUrlFromChainId(config.chainId), txnHash);
      if (txnReceipt?.status) {
        await cancelOfferBackendRequest(offer.offerHash);

        ScaffoldMessenger.of(context).showSnackBar(
          returnSnackBarWidget(context.loc.successHeadingSnackbar,
              context.loc.tokenRedeemed, 'success'),
        );

        //refresh providers for ownerchip check on ResultScreen
        await ref.refresh(nftOwnerProvider.future);
        await ref.refresh(creatorDataProvider.future);
        await ref.refresh(voucherContractAndTwinNftOwnerProvider.future);

        setState(() {
          isRotating = false;
          loadingSvgPath = "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/mint.svg";
          loadingText = context.loc.tokenRedeemed;
        });

        //delay two seconds
        await Future.delayed(const Duration(seconds: 2));

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
    final ChipInfoModel chipInfo = ref.watch(chipInfoProvider);
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
    final AsyncValue<List> voucherContractAndTwinNftOwner =
        ref.watch(voucherContractAndTwinNftOwnerProvider);

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
                          data: (data) => data['name'] != null
                              ? GestureDetector(
                                  onTap: () {
                                    Navigator.of(context)
                                        .pushNamed(NFTDetailsScreen.routeName);
                                  },
                                  child: Text(data['name'],
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
                                    data: ((data) => data.collectionId ==
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
                                      data: (data) =>
                                          data.collectionId == zeroAddress
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
                                                  data: (data) =>
                                                      CreatorDataBoxContent(
                                                          creatorData: data),
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
                                    data: ((data) => userSession == null
                                        ?
                                        //NFT owner exists and wallet is NOT connected
                                        SvgPicture.asset(
                                            "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/triangle_small.svg")
                                        : connectedWallet == data
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
                                  child: nftOwner.when(
                                      data: (data) => connectedWallet ==
                                                  zeroAddress ||
                                              userSession == null
                                          ?
                                          //NFT owner exists and wallet is NOT connected
                                          Column(
                                              children: [
                                                Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Text(
                                                        context.loc
                                                            .noWalletConnected,
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: Theme.of(context)
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
                                            )
                                          : connectedWallet == data
                                              //NFT owner exists and wallet is connected and wallet is owner
                                              ? approval.value == zeroAddress
                                                  // show transfer / burn Token buttons only if token is not approved
                                                  ? Column(
                                                      children: [
                                                        // YOU ARE THE OWNER TEXT
                                                        Align(
                                                            alignment: Alignment
                                                                .centerLeft,
                                                            child: Text(
                                                                context.loc
                                                                    .youAreNftOwner,
                                                                textAlign:
                                                                    TextAlign
                                                                        .left,
                                                                style: Theme.of(
                                                                        context)
                                                                    .textTheme
                                                                    .bodyMedium)),
                                                        const SizedBox(
                                                            height: 10),
                                                        // TRANSFER BUTTON
                                                        CustomRoundedButton(
                                                            text: context.loc
                                                                .transferToken,
                                                            onPressed: (() => {
                                                                  //navigate to transfer screen
                                                                  Navigator.pushNamed(
                                                                      context,
                                                                      TransferScreen
                                                                          .routeName)
                                                                })),
                                                        const SizedBox(
                                                            height: 10),
                                                        // BURN BUTTON
                                                        relevantCollections
                                                            .when(
                                                                data: (data) {
                                                                  //get collection where user is minter
                                                                  Collection collection = data.collections[tokenInfo.value!.chainId] !=
                                                                          null
                                                                      ? data.collections[tokenInfo.value!.chainId]!.firstWhere((element) => element.hasMinterRole!,
                                                                          orElse: () => Collection(
                                                                              zeroAddress,
                                                                              '',
                                                                              hasMinterRole:
                                                                                  false))
                                                                      : Collection(
                                                                          zeroAddress,
                                                                          '',
                                                                          hasMinterRole:
                                                                              false);
                                                                  return collection
                                                                          .hasMinterRole!
                                                                      ? Column(
                                                                          children: [
                                                                              // BURN BUTTON
                                                                              CustomOutlinedButton(
                                                                                  width: double
                                                                                      .infinity,
                                                                                  buttonText: context
                                                                                      .loc.burnToken,
                                                                                  onPressed: (() => {
                                                                                        fromCancelable(burnToken(wc, chipInfo.tokenId, signatureData, connectedWallet))
                                                                                      })),
                                                                            ])
                                                                      : Container();
                                                                },
                                                                error: (e, s) =>
                                                                    Container(),
                                                                loading: () =>
                                                                    Container())
                                                      ],
                                                    )
                                                  // if token is already approved, show hint
                                                  : Column(
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
                                                                TextAlign.left,
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .bodyMedium),
                                                      ],
                                                    )
                                              :
                                              //NFT owner exists and wallet is connected and wallet is NOT owner
                                              Column(children: [
                                                  Align(
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child: Text(
                                                          context.loc
                                                              .youAreNotNftOwner,
                                                          textAlign:
                                                              TextAlign.left,
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodyMedium)),
                                                  const SizedBox(height: 10),
                                                  creatorData.when(
                                                    //if seller wallet address is equal to connected wallet address, show cancel order button
                                                    data: (data) => data
                                                                .hasActiveOffer &&
                                                            EthereumAddress.fromHex(data
                                                                    .tokenForWhichCreatorDataWasRequested
                                                                    .activeOffers[
                                                                        0]
                                                                    .sellerAddress) ==
                                                                connectedWallet
                                                        ? CustomRoundedButton(
                                                            text:
                                                                'Cancel order',
                                                            onPressed: () {
                                                              fromCancelable(cancelOffer(
                                                                  wc,
                                                                  chipInfo
                                                                      .tokenId,
                                                                  signatureData,
                                                                  connectedWallet));
                                                            })
                                                        : Container(),
                                                    loading: () => Container(),
                                                    error: (e, s) =>
                                                        Container(),
                                                  ),
                                                  //REDEEM twin token if you have a voucher token and voucherTokenOwner is connectedWalet
                                                  voucherContractAddress.when(
                                                      data: (data) {
                                                        return vouchertokenOwner
                                                            .when(
                                                                data: (tokenOwner) => tokenOwner ==
                                                                            connectedWallet &&
                                                                        data !=
                                                                            null
                                                                    ? Column(
                                                                        children: [
                                                                            const SizedBox(height: 15),
                                                                            CustomRoundedButton(
                                                                                width: double.infinity,
                                                                                text: context.loc.redeemToken,
                                                                                onPressed: (() => {
                                                                                      fromCancelable(redeemTwinToken(wc, chipInfo.tokenId, signatureData, connectedWallet))
                                                                                    })),
                                                                          ])
                                                                    : Container(),
                                                                error: (e, s) =>
                                                                    Container(),
                                                                loading: () =>
                                                                    Container());

                                                        // nftOwnerProvider
                                                      },
                                                      error: (e, s) =>
                                                          Container(),
                                                      loading: () =>
                                                          Container()),

                                                  //CLAIM Ownership of twin token if it was transferred to user
                                                  approval.when(
                                                      data: (data) {
                                                        //check if a wallet can CLAIM OWNERSHIP
                                                        return data ==
                                                                connectedWallet
                                                            ? Column(children: [
                                                                const SizedBox(
                                                                    height: 15),
                                                                CustomRoundedButton(
                                                                    width: double
                                                                        .infinity,
                                                                    text: context
                                                                        .loc
                                                                        .claimOwnership,
                                                                    onPressed:
                                                                        (() => {
                                                                              fromCancelable(claimToken(wc, chipInfo.tokenId, signatureData, connectedWallet))
                                                                            })),
                                                              ])
                                                            : Container();
                                                      },
                                                      error: (e, s) =>
                                                          Container(),
                                                      loading: () =>
                                                          Container())
                                                ]),
                                      error: (e, s) => Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                              context.loc.youAreNotNftOwner,
                                              textAlign: TextAlign.left,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium)),
                                      loading: () =>
                                          const CircularProgressIndicator())),
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
                        data: (data) => CustomImage(
                          width: 130,
                          loading: false,
                          imagePath: data,
                        ),
                      )),
                ],
              ),
              const SizedBox(height: 20),

              //if token does not exists
              tokenInfo.when(
                  data: (data) => data.collectionId == zeroAddress &&
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
                      : data.collectionId == zeroAddress
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
