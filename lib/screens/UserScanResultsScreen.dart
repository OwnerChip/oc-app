//import packages
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';

//import misc
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/screens/ChainSelectorScreen.dart';
import 'package:ownerchip_whitelabel/screens/HomeScreen.dart';

//import screens
import 'package:ownerchip_whitelabel/screens/NFTDetailsScreen.dart';
import 'package:ownerchip_whitelabel/screens/nftActionsScreenMixin.dart';
import 'package:ownerchip_whitelabel/services/providers/chipData.dart';
import 'package:ownerchip_whitelabel/services/providers/collectionsData.dart';
import 'package:ownerchip_whitelabel/services/providers/nftData.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';

//import services
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/globals.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/utils/navigationArguments.dart';
import 'package:ownerchip_whitelabel/utils/urls.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';
import 'package:ownerchip_whitelabel/widgets/popups/CustomOverlay.dart';
import 'package:ownerchip_whitelabel/widgets/popups/WalletPopUp.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CreatorDataBoxContent.dart';

//import widgets
import 'package:ownerchip_whitelabel/widgets/ui/CustomCard.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomImage.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/RefreshMetadataButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/SpinningLoadingSvg.dart';
import 'package:ownerchip_whitelabel/widgets/ui/appBar/CustomAppBar.dart';
import 'package:sentry/sentry.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:web3dart/web3dart.dart';

class UserScanResultsScreen extends ConsumerStatefulWidget {
  const UserScanResultsScreen({super.key});

  static const routeName = '/user-scan-results';

  @override
  _UserScanResultsScreenState createState() => _UserScanResultsScreenState();
}

class _UserScanResultsScreenState extends ConsumerState<UserScanResultsScreen>
    with NftActionScreenMixin<UserScanResultsScreen> {
  bool loadingImage = true;

  Future<void> launchWallet() async {
    await launchUrlString('wc:', mode: LaunchMode.externalApplication);
  }

  @override
  void initState() {
    super.initState();
    pageKey = 'UserScanResultsScreen';
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
    final wc = ref.watch(w3mServiceProvider);
    final AsyncValue<CreatorData> creatorData = ref.watch(creatorDataProvider);

    // if token is transferred, and ready to be claimed restore deferred session

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
                        if (tokenInfo.isLoading)
                          CircularProgressIndicator(
                            color:
                                CustomColors(dotenv.get("APP_ID")).accentColor,
                          )
                        else if (tokenInfo.hasValue &&
                            tokenInfo.asData?.value.collectionId ==
                                zeroAddress) ...[
                          Text(
                            context.loc
                                .scanResultPage_chipHasNotYetBeenInitialized,
                            style: Theme.of(context).textTheme.headlineMedium,
                            textAlign: TextAlign.center,
                          )
                        ] else ...[
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
                                        data: (tokenInfoData) => tokenInfoData
                                                    .collectionId ==
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
                                                  creatorData: creatorDataData,
                                                  chipAddress: chipInfo
                                                      .chipEthereumAddress.hex,
                                                ),
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
                                    Text(
                                        context
                                            .loc.scanResultPage_ownershipCheck,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium),

                                    //OWNERSHIP CHECK ICON
                                    nftOwner.when(
                                      data: (nftOwnerData) => userSession == null
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
                                                  "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/alert_cross.svg"),
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
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .bodyMedium)),
                                                      const SizedBox(
                                                          height: 10),
                                                      CustomRoundedButton(
                                                          text: context.loc
                                                              .connectWallet,
                                                          onPressed: (() => {
                                                                walletPopupBuilder(
                                                                    context,
                                                                    ref)
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
                                                                                tokenInfo.value!.collectionId,
                                                                            orElse: () => Collection(zeroAddress, '', hasMinterRole: false));
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
                                                                              child: Text(
                                                                                context.loc.scanResultPage_ownershipOwnerNotOffered,
                                                                                textAlign: TextAlign.left,
                                                                                style: Theme.of(context).textTheme.bodyMedium,
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        );
                                                                      } else {
                                                                        // USER DOES NOT HAVE MINTER ROLE FOR THIS TOKENS COLLECTION
                                                                        return Column(
                                                                          children: [
                                                                            Align(
                                                                              alignment: Alignment.centerLeft,
                                                                              child: Text(
                                                                                context.loc.scanResultPage_ownershipOwnerNotOffered,
                                                                                textAlign: TextAlign.left,
                                                                                style: Theme.of(context).textTheme.bodyMedium,
                                                                              ),
                                                                            ),
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
                                                                        getEthAddressSubstring(approval
                                                                            .value!) +
                                                                        context
                                                                            .loc
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
                                                            return Text(
                                                                context.loc
                                                                    .scanResultPage_ownershipNotOwnerNotOffered,
                                                                textAlign:
                                                                    TextAlign
                                                                        .left,
                                                                style: Theme.of(
                                                                        context)
                                                                    .textTheme
                                                                    .bodyMedium);
                                                          } else {
                                                            //TOKEN IS APPROVED / IS READY TO BE CLAIMED
                                                            return approval
                                                                .when(
                                                                    data:
                                                                        (approvalData) {
                                                                      if (approvalData ==
                                                                          connectedWallet) {
                                                                        //USER IS APPROVED TO CLAIM
                                                                        return Column(
                                                                          children: [
                                                                            Align(
                                                                                alignment: Alignment.centerLeft,
                                                                                child: Text(context.loc.youAreTheNewOwner, textAlign: TextAlign.left, style: Theme.of(context).textTheme.bodyMedium)),
                                                                            const SizedBox(height: 10),
                                                                            CustomRoundedButton(
                                                                                width: double
                                                                                    .infinity,
                                                                                text: context
                                                                                    .loc.claimOwnership,
                                                                                onPressed: (() => {
                                                                                      fromCancelable(claimToken(wc, chipInfo.tokenId, signatureData, connectedWallet))
                                                                                    }))
                                                                          ],
                                                                        );
                                                                      } else {
                                                                        //USER IS NOT APPROVED TO CLAIM
                                                                        return Text(
                                                                            context
                                                                                .loc.scanResultPage_ownershipNotOwnerNotOffered,
                                                                            textAlign:
                                                                                TextAlign.left,
                                                                            style: Theme.of(context).textTheme.bodyMedium);
                                                                      }
                                                                    },
                                                                    loading: () =>
                                                                        Container(),
                                                                    error: (e,
                                                                            s) =>
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
                                                  context.loc
                                                      .scanResultPage_ownershipNotOwnerNotOffered,
                                                  textAlign: TextAlign.left,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium))
                                    )
                              ]),
                        ]
                      ]),
                  GestureDetector(
                      onTap: () {
                        Navigator.of(context)
                            .pushNamed(NFTDetailsScreen.routeName);
                      },
                      child: nftImageUri.when(
                        loading: () => const CustomImage(
                          width: 130,
                          height: 130,
                          loading: true,
                        ),
                        error: (e, s) => const CustomImage(
                          width: 130,
                          height: 130,
                          loading: false,
                        ),
                        data: (nftImageUriData) => CustomImage(
                          width: 130,
                          height: 130,
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
                                // await initializeItem(ref, context);
                                Navigator.pushNamed(
                                  context,
                                  ChainSelectorScreen.routeName,
                                  arguments: MetadataInputScreenArguments(
                                    0,
                                    zeroAddress,
                                  ),
                                );
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
                loading: () => Container(),
              ),

              tokenInfo.when(
                data: (tokenInfoData) {
                  if (tokenInfoData.collectionId == zeroAddress &&
                      userSession == null) {
                    return CustomRoundedButton(
                      text: context.loc.connectWallet,
                      onPressed: (() {
                        walletPopupBuilder(context, ref);
                      }),
                    );
                  }

                  if (dotenv.get('APP_ID') == "ownerchip") {
                    if (tokenInfoData.collectionId == zeroAddress &&
                        userSession != null &&
                        !userSession.jwt.canMint()) {
                      return CustomRoundedButton(
                          text: context.loc.signupAsCertifier,
                          onPressed: () {
                            launchUrl(Uri.parse(
                                getBecomeACreatorUrl(userSession.jwt.raw)));
                          });
                    }
                  }

                  return const SizedBox();
                },
                error: (e, s) => Container(),
                loading: () => Container(),
              ),

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
