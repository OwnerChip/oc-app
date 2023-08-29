//import packages
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ownerchip_whitelabel/services/scan.services.dart';
import 'package:ownerchip_whitelabel/widgets/popups/CustomOverlay.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomOutlinedButton.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:web3dart/web3dart.dart';
import 'package:sentry/sentry.dart';
import 'package:async/async.dart';

//import services
import 'package:ownerchip_whitelabel/services/providers.services.dart';
import 'package:ownerchip_whitelabel/services/wallet.services.dart';
import 'package:ownerchip_whitelabel/services/backend.services.dart';
import 'package:ownerchip_whitelabel/services/web3.services.dart';
import 'package:ownerchip_whitelabel/services/attachments.services.dart';

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

  Future<void> burnToken(Web3App wc, BigInt tokenId,
      SignatureData signatureData, EthereumAddress connectedWallet) async {
    final wcSession = ref.watch(wcSessionProvider);
    final walletType = ref.read(walletTypeProvider);
    String sessionId = ref.read(userSessionProvider)!.sessionId;
    final TokenInfoObject config =
        await ref.watch(findTokenProvider(tokenId).future);
    final burnProcess = Sentry.startTransaction('initBurn()', 'task');
    try {
      setState(() {
        isLoading = true;
        loadingText = context.loc.burning;
      });

      sendAnalyticsTrace(sessionId.toString(), "", "BURN_STARTED", tags: {
        'connectedWallet': connectedWallet,
        'tokenId': tokenId.toString()
      });

      final List response =
          await checkMetaTx(config.collectionId, gaslessBurnFunctionSignature);
      final bool canUseGasStation = response[0];
      final metaTxAgreementId = response[1];

      String txnHash;

      if (canUseGasStation) {
        txnHash = await makeAndSendGaslessTx(
            ref,
            context,
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

        UserSession? userSession = ref.read(userSessionProvider);

        deleteAllAttachments(userSession!, connectedWallet, config.chainId,
            config.collectionId, tokenId, signatureData);
        // send status to analytics
        burnProcess.finish();
        sendAnalyticsTrace(sessionId, txnHash, "BURN_SUCCESS", tags: {
          'connectedWallet': connectedWallet,
          'tokenId': tokenId.toString()
        });

        await Future.delayed(const Duration(seconds: 2));

        Navigator.pushNamedAndRemoveUntil(
            context, HomeScreen.routeName, (route) => false);
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
        'connectedWallet': connectedWallet,
        'tokenId': tokenId.toString()
      });
      await Sentry.captureException(e, stackTrace: s);
      ScaffoldMessenger.of(context).showSnackBar(
        returnSnackBarWidget(
            context.loc.errorHeadingSnackBar, context.loc.burnedError, 'error'),
      );
      print("Error: $e");
    }
  }

  Future<void> claimToken(Web3App wc, BigInt tokenId,
      SignatureData signatureData, EthereumAddress connectedWallet) async {
    final wcSession = ref.watch(wcSessionProvider);
    final walletType = ref.read(walletTypeProvider);
    String sessionId = ref.read(userSessionProvider)!.sessionId;
    final TokenInfoObject config =
        await ref.watch(findTokenProvider(tokenId).future);
    final claimProcess = Sentry.startTransaction('initClaim()', 'task');
    try {
      if (wcSession == null || walletType == null) {
        walletPopupBuilder(context, ref, wc);
      }

      setState(() {
        isLoading = true;
        loadingText = context.loc.transferInProgress;
      });

      sendAnalyticsTrace(sessionId.toString(), "", "CLAIM_STARTED", tags: {
        'connectedWallet': connectedWallet,
        'tokenId': tokenId.toString()
      });

      final List response = await checkMetaTx(
          config.collectionId, transferToCardFunctionSignature);
      final bool canUseGasStation = response[0];
      final metaTxAgreementId = response[1];

      String txnHash;

      if (canUseGasStation) {
        txnHash = await makeAndSendGaslessTx(
            ref,
            context,
            transferToCardFunctionSignature,
            config.chainId,
            config.collectionId,
            signatureData,
            connectedWallet,
            wc,
            wcSession!,
            metaTxAgreementId,
            walletType!,
            tokenId: tokenId,
            toggleLoading: toggleLoading);
      } else {
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
        //this means claiming token succeeded
        setState(() {
          isRotating = false;
          loadingSvgPath = "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/mint.svg";
          loadingText = context.loc.transferSuccess;
        });

        // send status to analytics
        claimProcess.finish();
        sendAnalyticsTrace(sessionId, txnHash, "CLAIM_SUCCESS", tags: {
          'connectedWallet': connectedWallet,
          'tokenId': tokenId.toString()
        });

        await Future.delayed(const Duration(seconds: 2));

        Navigator.pushNamedAndRemoveUntil(
            context, HomeScreen.routeName, (route) => false);
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
        'connectedWallet': connectedWallet,
        'tokenId': tokenId.toString()
      });
      await Sentry.captureException(e, stackTrace: s);
      ScaffoldMessenger.of(context).showSnackBar(
        returnSnackBarWidget(context.loc.errorHeadingSnackBar,
            context.loc.transferError, 'error'),
      );
      print("Error: $e");
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
    // ref.watch(fetchAttachmentsProvider
    //     .future); //Trigger loading of attachments, but don't use it here

    final ChipInfoModel chipInfo = ref.watch(chipInfoProvider);
    final AsyncValue<String> nftImageUri =
        ref.watch(nftImageProvider(chipInfo.tokenId));
    final AsyncValue<Map<String, dynamic>> nftMetadata =
        ref.watch(nftMetadataProvider(chipInfo.tokenId));
    final AsyncValue<EthereumAddress> nftOwner = ref.watch(nftOwnerProvider);
    final AsyncValue<EthereumAddress> approval = ref.watch(nftApprovalProvider);
    final AsyncValue<TokenInfoObject> tokenInfo =
        ref.watch(findTokenProvider(chipInfo.tokenId));

    final wc = ref.watch(wcProvider);
    final wcSession = ref.watch(wcSessionProvider);
    AsyncValue<BlockchainCollectionList> relevantCollections =
        ref.watch(findAllMinterRolesProvider);
    final EthereumAddress connectedWallet = ref.watch(userAddressProvider);
    final SignatureData signatureData = ref.watch(chipSignatureDataProvider);

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
          // enable secondary button
          secondaryButton: true,
          secondaryButtonText: context.loc.troubleshoot,
          secondaryButtonUrl: dotenv.get('SUPPORT_PAGE_URL'),
        ),
        child: Scaffold(
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
                              ? Text(data['name'],
                                  style:
                                      Theme.of(context).textTheme.displayLarge!)
                              : Container(),
                          error: (error, stackTrace) => Container(),
                        ),
                        const SizedBox(height: 10),
                        //AUTHENTICITY CHECK
                        CustomCard(
                            color: CustomColors(dotenv.get('APP_ID'))
                                .scaffoldBackgroundColor,
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
                                      data: (data) => data.collectionId ==
                                              zeroAddress
                                          ? Text(context.loc.authenticityNftNotFound,
                                              textAlign: TextAlign.left,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium)
                                          : Text(
                                              context.loc.authenticityNftFound,
                                              textAlign: TextAlign.left,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium),
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
                                .scaffoldBackgroundColor,
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
                                    data: ((data) => connectedWallet ==
                                            zeroAddress
                                        ?
                                        //NFT owner exists and wallet is NOT connected
                                        SvgPicture.asset(
                                            "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/triangle_small.svg")
                                        : connectedWallet == data
                                            ?
                                            //NFT owner exists and wallet is connected and wallet is owner
                                            SvgPicture.asset(
                                                "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/check.svg")
                                            :
                                            //NFT owner exists and wallet is connected and wallet is NOT owner
                                            SvgPicture.asset(
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
                                              zeroAddress
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
                                                              context, ref, wc!)
                                                        }))
                                              ],
                                            )
                                          : connectedWallet == data
                                              ?
                                              //NFT owner exists and wallet is connected and wallet is owner
                                              Column(
                                                  children: [
                                                    Align(
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        child: Text(
                                                            context.loc
                                                                .youAreNftOwner,
                                                            textAlign:
                                                                TextAlign.left,
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .bodyMedium)),
                                                    const SizedBox(height: 10),
                                                    CustomRoundedButton(
                                                        text: context
                                                            .loc.transferToken,
                                                        onPressed: (() => {
                                                              //navigate to transfer screen
                                                              Navigator.pushNamed(
                                                                  context,
                                                                  TransferScreen
                                                                      .routeName)
                                                            })),
                                                    const SizedBox(height: 10),
                                                    relevantCollections.when(
                                                        data: (data) {
                                                          //get collection where user is minter
                                                          Collection collection = data.collections[tokenInfo.value!.chainId] != null
                                                              ? data.collections[tokenInfo.value!.chainId]!.firstWhere(
                                                                  (element) => element
                                                                      .hasMinterRole!,
                                                                  orElse: () => Collection(
                                                                      zeroAddress, '',
                                                                      hasMinterRole:
                                                                          false))
                                                              : Collection(
                                                                  zeroAddress, '',
                                                                  hasMinterRole:
                                                                      false);
                                                          return collection
                                                                  .hasMinterRole!
                                                              ? Column(
                                                                  children: [
                                                                      CustomOutlinedButton(
                                                                          width: double
                                                                              .infinity,
                                                                          buttonText: context
                                                                              .loc
                                                                              .burnToken,
                                                                          onPressed: (() =>
                                                                              {
                                                                                fromCancelable(burnToken(wc!, chipInfo.tokenId, signatureData, connectedWallet))
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
                                                                    text:
                                                                        "Claim Ownership",
                                                                    onPressed:
                                                                        (() => {
                                                                              fromCancelable(claimToken(wc!, chipInfo.tokenId, signatureData, connectedWallet))
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
                  nftImageUri.when(
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
                  ),
                ],
              ),
              const SizedBox(height: 20),

              //if token does not exists
              tokenInfo.when(
                  data: (data) => data.collectionId == zeroAddress &&
                          connectedWallet != zeroAddress &&
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
            ])));
  }
}
