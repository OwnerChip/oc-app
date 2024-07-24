import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/domain/creation/digitalTwinMetadata.dart';
import 'package:ownerchip_whitelabel/screens/offer/OfferForSaleCreatedTokenScreen.dart';
import 'package:ownerchip_whitelabel/services/backend/app/backendApp.dart';
import 'package:ownerchip_whitelabel/services/backend/creation/backendCreation.dart';
import 'package:ownerchip_whitelabel/services/backend/metaTx/backendMetaTx.dart';
import 'package:ownerchip_whitelabel/services/nfc.services.dart';
import 'package:ownerchip_whitelabel/services/providers/chipData.dart';
import 'package:ownerchip_whitelabel/services/providers/collectionsData.dart';
import 'package:ownerchip_whitelabel/services/providers/creations/creationsData.dart';
import 'package:ownerchip_whitelabel/services/providers/creations/creationsNotifier.dart';
import 'package:ownerchip_whitelabel/services/providers/nftData.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/services/wallet.services.dart';
import 'package:ownerchip_whitelabel/services/web3.services.dart';
import 'package:ownerchip_whitelabel/utils/globals.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:ownerchip_whitelabel/widgets/popups/CustomOverlay.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:ownerchip_whitelabel/widgets/ui/SpinningLoadingSvg.dart';
import 'package:ownerchip_whitelabel/widgets/ui/appBar/CustomAppBar.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

class CreationsPage extends ConsumerStatefulWidget {
  const CreationsPage({super.key});

  static String routeName = '/creations';

  @override
  ConsumerState<CreationsPage> createState() => _CreationsPageState();
}

class _CreationsPageState extends ConsumerState<CreationsPage> {
  bool isLoading = false;
  String overlayContentType = 'loading'; //can be "traits" or "loading"
  String loadingText = '';
  String loadingSvgPath =
      '${dotenv.get('IMAGE_ASSETS_BASE_URL')}/chip_dark_blue.svg';

  final RefreshController _refreshController = RefreshController();

  Future<void> toggleLoading() async {
    setState(() {
      isLoading = !isLoading;
    });
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> createToken(
    String sessionId,
    Web3App? wc,
    SignatureData signatureData,
    DigitalTwinMetadata metadata,
  ) async {
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
      //check if user is allowed to use gas station
      final List response = await BackendMetaTx.checkMetaTx(
        EthereumAddress.fromHex(metadata.collectionId),
        mintFunctionSignature,
      );
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

      int chainId = 137;

      Future<void> normalTx() async {
        txnHash = await makeAndSendNormalTx(
            context,
            ref,
            mintVoucherFunctionSignature,
            chainId,
            EthereumAddress.fromHex(metadata.collection.voucherAddress),
            signatureData,
            connectedWallet,
            wc!,
            wcSession,
            walletType!,
            twinTokenMetadataCID: metadata.twinTokenMetadataCID,
            voucherTokenMetadataCID: metadata.voucherTokenMetadataCID);
      }

      try {
        if (canUseGasStation) {
          txnHash = await makeAndSendGaslessTx(
              ref,
              ScaffoldKey.getScaffoldKey('CreationsPage').currentContext!,
              mintVoucherFunctionSignature,
              chainId,
              EthereumAddress.fromHex(metadata.collection.voucherAddress),
              signatureData,
              connectedWallet,
              wc,
              wcSession,
              metaTxAgreementId,
              walletType!,
              twinTokenMetadataCID: metadata.twinTokenMetadataCID,
              voucherTokenMetadataCID: metadata.voucherTokenMetadataCID,
              toggleLoading: toggleLoading);
        } else {
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

        final chipInfo = ref.read(chipInfoProvider);
        BackendCreation.markDigitalTwinAsMinted(id: metadata.id, chipId: chipInfo.chipEthereumAddress.hex);

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

  @override
  Widget build(BuildContext context) {
    final creations = ref.watch(creationsNotifierProvider);
    return CustomOverlay(
      show: isLoading,
      content: SpinningLoadingSvg(
        onPressed: () {
          setState(() {
            isLoading = false;
          });
        },
        loadingText: loadingText,
        rotateIcon: true,
        svgPath: loadingSvgPath,
      ),
      child: Scaffold(
          key: ScaffoldKey.getScaffoldKey('CreationsPage'),
          appBar: CustomAppBar(),
          body: SmartRefresher(
            enablePullDown: true,
            enablePullUp: false,
            controller: _refreshController,
            onRefresh: () async {
              await ref.read(creationsNotifierProvider.notifier).init();
              _refreshController.refreshCompleted();
            },
            child: ListView.builder(
              itemCount: creations.data?.data.length ?? 0,
              itemBuilder: (context, index) {
                final metadata = creations.data!.data[index];
                return InkWell(
                  onTap: () {
                    _mintItem(
                      context,
                      creations,
                      metadata,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Flexible(
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 16,
                          ),
                          if (metadata.imageLink != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                8.0,
                              ),
                              child: SizedBox(
                                width: 96,
                                height: 96,
                                child: Image.network(
                                  metadata.imageLink!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          else
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          const SizedBox(
                            width: 32,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  metadata.title,
                                  style: Theme.of(context).textTheme.headlineMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  metadata.description,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          )),
    );
  }

  Future<void> _mintItem(
    BuildContext context,
    CreationsData creations,
    DigitalTwinMetadata metadata,
  ) async {
    await scanItem(
      ref,
      context,
      navigateToResultPage: false,
    );

    final userSession = ref.read(userSessionProvider)!;
    final wc = ref.read(wcProvider);

    createToken(
      userSession.sessionId,
      wc!,
      ref.read(chipSignatureDataProvider),
      metadata,
    );
  }
}
