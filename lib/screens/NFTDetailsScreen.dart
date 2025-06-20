//import packages
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ownerchip_whitelabel/config/chains.dart';
import 'package:ownerchip_whitelabel/config/collections.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/domain/creation/digitalTwinMetadata.dart';
import 'package:ownerchip_whitelabel/domain/local_attachment.dart';
import 'package:ownerchip_whitelabel/domain/tokenTypes.dart';
import 'package:ownerchip_whitelabel/screens/ListAttachmentsScreen.dart';
import 'package:ownerchip_whitelabel/screens/TransferScreen.dart';
import 'package:ownerchip_whitelabel/screens/nftActionsScreenMixin.dart';
import 'package:ownerchip_whitelabel/screens/offer/OfferOnMPScreen.dart';
import 'package:ownerchip_whitelabel/services/backend/app/backendApp.dart';
import 'package:ownerchip_whitelabel/services/nfc.services.dart';
import 'package:ownerchip_whitelabel/services/providers/attachmentsData.dart';
import 'package:ownerchip_whitelabel/services/providers/blockchainData.dart';
import 'package:ownerchip_whitelabel/services/providers/chipData.dart';
import 'package:ownerchip_whitelabel/services/providers/collectionsData.dart';
import 'package:ownerchip_whitelabel/services/providers/creationData.dart';
import 'package:ownerchip_whitelabel/services/providers/nftData.dart';
import 'package:ownerchip_whitelabel/services/providers/urlData.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/themes/fontSpecs.dart';
import 'package:ownerchip_whitelabel/utils/globals.dart';

//import misc
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/utils/urls.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';
import 'package:ownerchip_whitelabel/widgets/popups/CustomOverlay.dart';
import 'package:ownerchip_whitelabel/widgets/ui/AttachmentBox.dart';
import 'package:ownerchip_whitelabel/widgets/ui/BigIconButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomCard.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomImage.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/DisplayLongStringWithCopy.dart';
import 'package:ownerchip_whitelabel/widgets/ui/DropdownContainer.dart';
import 'package:ownerchip_whitelabel/widgets/ui/InfoKeyValues.dart';
import 'package:ownerchip_whitelabel/widgets/ui/RefreshMetadataButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/SpinningLoadingSvg.dart';

//import widgets
import 'package:ownerchip_whitelabel/widgets/ui/appBar/CustomAppBar.dart';
import 'package:reown_appkit/reown_appkit.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/popups/CustomPopup.dart';

class NFTDetailsScreen extends ConsumerStatefulWidget {
  const NFTDetailsScreen({super.key});

  static const routeName = '/nft-details';

  @override
  _NFTDetailsScreen createState() => _NFTDetailsScreen();
}

class _NFTDetailsScreen extends ConsumerState<NFTDetailsScreen>
    with NftActionScreenMixin<NFTDetailsScreen> {
  // 12 july 2024 13:15:01 CET
  final DateFormat formatter = DateFormat('dd MMMM yyyy HH:mm:ss z');

  @override
  void initState() {
    super.initState();
    pageKey = 'NFTDetailsScreen';
  }

  @override
  Widget build(BuildContext context) {
    final userSession = ref.watch(userSessionProvider);
    final ChipInfoModel chipInfo = ref.watch(chipInfoProvider);
    final activeOffers = ref.watch(activeOffersProvider);
    final AsyncValue<Map<String, dynamic>> nftMetadata =
        ref.watch(nftMetadataProvider(chipInfo.tokenId));
    final AsyncValue<String> nftImageUri =
        ref.watch(nftImageProvider(chipInfo.tokenId));
    final AsyncValue<TokenChainAndCollection> tokenInfo =
        ref.watch(findTokenProvider(chipInfo.tokenId));
    final wc = ref.watch(w3mServiceProvider);
    final  weblinkUrl = ref.watch(webLinkUrlProvider);
    final AsyncValue<Uri> raribleUrl = ref.watch(raribleUrlProvider);
    final AsyncValue<Uri> openseaUrl = ref.watch(openseaUrlProvider);
    final AsyncValue<Uri> blockchainExplorerUrl =
        ref.watch(blockchainExplorerUrlProvider);
    final AsyncValue<BlockchainCollectionList> relevantCollections =
        ref.watch(findAllMinterRolesProvider);
    final AsyncValue<String> contractName = ref.watch(contractNameProvider);
    final AsyncValue<EthereumAddress> nftOwner = ref.watch(nftOwnerProvider);
    final EthereumAddress connectedWallet = ref.watch(userAddressProvider);
    final AsyncValue<List<LocalAttachment>> fetchedAttachments = ref.watch(
        fetchAttachmentsProvider); //Trigger loading of attachments, which are saved to localAttachmentsProvider
    List<LocalAttachment> attachments = ref.watch(localAttachmentsProvider);
    List<LocalAttachment> ownerAttachments = ref.watch(ownerAttachmentsProvider);
    List<LocalAttachment> creatorAttachments = ref.watch(creatorAttachmentsProvider);
    // creator data
    final creatorData = ref.watch(creatorDataProvider);
    final AsyncValue<List?> voucherContractAndTwinNftOwner =
        ref.watch(voucherContractAndTwinNftOwnerProvider);
    final AsyncValue<EthereumAddress> approval = ref.watch(nftApprovalProvider);
    final AsyncValue<EthereumAddress?> voucherContractAddress =
        ref.watch(voucherContractProvider);
    final AsyncValue<EthereumAddress?> vouchertokenOwner =
        ref.watch(voucherTokenOwnerProvider);
    final AsyncValue<EthereumAddress> lastSellerAddress =
        ref.watch(lastSellerAddressProvider);
    final digitalTwinMetadata = ref.watch(digitalTwinCreationMetadataProvider);

    Widget buildButtons({
      DigitalTwinMetadata? digitalTwinMetadata,
    }) {
      return _buildButtons(
        nftOwner,
        connectedWallet,
        approval,
        voucherContractAndTwinNftOwner,
        context,
        activeOffers,
        userSession,
        relevantCollections,
        tokenInfo,
        wc,
        chipInfo,
        voucherContractAddress,
        vouchertokenOwner,
        lastSellerAddress,
        raribleUrl,
        digitalTwinMetadata: digitalTwinMetadata,
      );
    }

    return CustomOverlay(
      show: isLoading,
      content: SpinningLoadingSvg(
        onPressed: () {
          cancellableOperation?.cancel();
          setState(() {
            isLoading = false;
          });
        },
        loadingText: loadingText,
        rotateIcon: isRotating,
        svgPath: loadingSvgPath,
      ),
      child: Scaffold(
        key: ScaffoldKey.getScaffoldKey('NFTDetailsScreen'),
        extendBodyBehindAppBar: true,
        appBar: CustomAppBar(
          text: context.loc.nftDetails,
        ),
        body: ScreenBodyLayout(
          children: [
            CustomCard(
              children: [
                nftImageUri.when(
                  loading: () => CustomImage(
                    loading: true,
                    tokenId: chipInfo.tokenId,
                  ),
                  error: (e, s) {
                    return CustomImage(
                      loading: true,
                      tokenId: chipInfo.tokenId,
                    );
                  },
                  data: (data) => CustomImage(
                    loading: false,
                    imagePath: data,
                    tokenId: chipInfo.tokenId,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: nftMetadata.when(
                          loading: () => Text(context.loc.loading,
                              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                  fontSize: CustomFonts(dotenv.get('APP_ID'))
                                      .metadataNameFontSize,
                                  fontWeight: CustomFonts(dotenv.get('APP_ID'))
                                      .metadataNameFontWeight)),
                          data: (data) => Text(data['name'] ?? "",
                              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                  fontSize: CustomFonts(dotenv.get('APP_ID'))
                                      .metadataNameFontSize,
                                  fontWeight: CustomFonts(dotenv.get('APP_ID'))
                                      .metadataNameFontWeight)),
                          error: (e, s) => RefreshMetadataButton()),
                    ),
                  ],
                ),
                Divider(
                  color: Theme.of(context).primaryColor,
                  height: 20,
                  thickness: 1,
                  indent: 0,
                  endIndent: 0,
                ),
                digitalTwinMetadata.when(
                    data: (creation) {
                      return buildButtons(digitalTwinMetadata: creation);
                    },
                    error: (e, s) => buildButtons(),
                    loading: () {
                      return const SizedBox();
                    }),

                /*** DESCRIPTION ***/
                nftMetadata.when(
                    data: (data) => data['description'] != null &&
                            data['description'].length > 0
                        ? DropdownContainer(
                            isInitiallyExpanded: true,
                            title: context.loc.description,
                            content: data['description'] != null
                                ? Linkify(
                                    onOpen: (link) async {
                                      if (!await launchUrl(
                                          Uri.parse(link.url))) {
                                        throw Exception(
                                            'Could not launch ${link.url}');
                                      }
                                      BackendApp.sendAnalyticsTrace(
                                          userSession?.sessionId ?? "",
                                          "",
                                          "DESCRIPTION_VIEW",
                                          tags: {
                                            'connectedWallet':
                                                connectedWallet.hex,
                                            'chipWallet':
                                                convertTokenIdToEthereumAddress(
                                                    ref
                                                        .read(chipInfoProvider)
                                                        .tokenId)
                                          });
                                    },
                                    text: data['description'],
                                  )
                                : null,
                          )
                        : Container(),
                    error: (e, s) => Container(),
                    loading: () => DropdownContainer(
                        title: context.loc.loading, content: null)),

                /*** TRAITS ***/
                nftMetadata.when(
                    data: (data) => data['traits'].isNotEmpty
                        ? DropdownContainer(
                            title: context.loc.traits,
                            content: InfoKeyValues(
                              keys: <String>[
                                ...data['traits']
                                    .map(
                                      (e) => e['trait_type'].toString(),
                                    )
                                    .toList()
                              ],
                              values: <String>[
                                ...data['traits']
                                    .map((e) => e['value'].toString())
                                    .toList()
                              ],
                            ))
                        : Container(),
                    error: (e, s) => Container(),
                    loading: () => DropdownContainer(
                        title: context.loc.loading, content: null)),

                /*** ATTACHMENTS ***/
                //fetchedAttachments.when() is a hack to show a loading widget, while the attachments are fetched.
                //The real attachment UI elements are NOT DIRECTLY dependent on fetchedAttachments,
                //because the attachments need to be edited locally, but this does not work in a FutureProvider.
                //Hence the attachments are displayed using localAttachmentsProvider data.
                fetchedAttachments.when(
                    data: (data) => Container(),
                    error: (e, s) => Container(),
                    loading: () => DropdownContainer(
                        title: context.loc.loading, content: null)),
                //if attachments are not empty --> show dropdown container
                //if attachments are empty, but the connected wallet is the owner --> show dropdown container (so NFT owner can add documents)
                ((attachments.isNotEmpty ||
                            (nftOwner.hasValue &&
                                connectedWallet == nftOwner.value)) &&
                        dotenv.get('APP_ID') != 'ownerchip_infineon')
                    ? DropdownContainer(
                        title: 'Digital Content ' +
                            '(' +
                            attachments.length.toString() +
                            ')',
                        content: Column(
                          children: [
                            creatorAttachments.isNotEmpty
                                ? Column(
                                    children: [
                                      const Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          'Creator content',
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      ...creatorAttachments.map(
                                        (e) => Column(children: [
                                          AttachmentBox(
                                            text: e.title,
                                            icon: e.type == AttachmentType.url
                                                ? Icons.link
                                                : Icons.attach_file,
                                            isPrivate: e.isPrivate,
                                            onTap: () {
                                              launchUrl(Uri.parse(e.url),
                                                  mode: LaunchMode
                                                      .externalApplication);
                                              BackendApp.sendAnalyticsTrace(
                                                  userSession?.sessionId ?? "",
                                                  e.backendUuid,
                                                  "ATTACHMENT_VIEW",
                                                  tags: {
                                                    'connectedWallet':
                                                        connectedWallet.hex,
                                                    'chipWallet':
                                                        convertTokenIdToEthereumAddress(ref
                                                            .read(
                                                                chipInfoProvider)
                                                            .tokenId)
                                                  });
                                            },
                                          ),
                                          const SizedBox(height: 10),
                                        ]),
                                      ),
                                    ],
                                  )
                                : Container(),
                            ownerAttachments.isNotEmpty
                                ? Column(
                                    children: [
                                      const Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          'Owner content',
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      ...ownerAttachments.map(
                                        (e) => Column(children: [
                                          AttachmentBox(
                                            text: e.title,
                                            icon: e.type == AttachmentType.url
                                                ? Icons.link
                                                : Icons.attach_file,
                                            isPrivate: e.isPrivate,
                                            onTap: () {
                                              launchUrl(Uri.parse(e.url),
                                                  mode: LaunchMode
                                                      .externalApplication);
                                              BackendApp.sendAnalyticsTrace(
                                                  userSession?.sessionId ?? "",
                                                  e.backendUuid,
                                                  "ATTACHMENT_VIEW",
                                                  tags: {
                                                    'connectedWallet':
                                                        connectedWallet.hex,
                                                    'chipWallet':
                                                        convertTokenIdToEthereumAddress(ref
                                                            .read(
                                                                chipInfoProvider)
                                                            .tokenId)
                                                  });
                                            },
                                          ),
                                          const SizedBox(height: 10),
                                        ]),
                                      ),
                                    ],
                                  )
                                : Container(),

                            //if connected wallet is owner
                            nftOwner.when(
                              data: ((data) => data == connectedWallet
                                  ? Column(
                                      children: [
                                        const SizedBox(height: 10),
                                        CustomRoundedButton(
                                            text: context.loc.edit,
                                            onPressed: () => {
                                                  Navigator.pushNamed(
                                                      context,
                                                      ListAttachmentsScreen
                                                          .routeName)
                                                })
                                      ],
                                    )
                                  : Container()),
                              error: (e, s) => Container(),
                              loading: () => Container(),
                            ),
                          ],
                        ),
                      )
                    : Container(),

                /*** DIGITAL TWIN ***/
                tokenInfo.when(
                  data: (tokenInfoData) {
                    return DropdownContainer(
                        title: context.loc.digitalTwin,
                        content: Column(
                          children: [
                            InfoKeyValues(keys: [
                              context.loc.authenticity,
                              context.loc.nftDetailsPageCertifier,
                              context.loc.nftDetailsPageCreationDate,
                            ], values: [
                              // authenticity
                              tokenInfo.when(
                                data: ((data) => data.collectionId ==
                                        zeroAddress
                                    ? context.loc
                                        .nftDetailsPageAuthenticityNotCertified
                                    : context.loc
                                        .nftDetailsPageAuthenticityCertified),
                                error: (e, s) => context
                                    .loc.nftDetailsPageAuthenticityCertified,
                                loading: () => context.loc.loading,
                              ),
                              // ownership
                              creatorData.when(
                                data: (nftCreatorData) {
                                  return nftCreatorData.name;
                                },
                                error: (e, s) => context
                                    .loc.nftDetailsErrorFetchingCertificateData,
                                loading: () => context.loc.loading,
                              ),
                              // creation date
                              creatorData.when(
                                data: (nftCreatorData) {
                                  return formatter
                                      .format(nftCreatorData.createdAt);
                                },
                                error: (e, s) => context
                                    .loc.nftDetailsErrorFetchingCertificateData,
                                loading: () => context.loc.loading,
                              ),
                            ]),
                            //if tokenInfo could not be loaded and hence chainId is zero, display empty container
                            tokenInfoData.chainId == 0
                                ? Container()
                                : InfoKeyValues(keys: [
                                    context.loc.nftDetailsPageCollection,
                                    "Blockchain",
                                    "Token ID",
                                  ], values: [
                                    // first, try to find collection in collections list
                                    (allCollections.collections[
                                                tokenInfoData.chainId] ??
                                            [])
                                        .firstWhere((collection) {
                                      return collection.id ==
                                          tokenInfoData.collectionId;
                                    },
                                            // if not found, check chain data
                                            orElse: () => Collection(
                                                tokenInfoData.collectionId,
                                                contractName.when(
                                                  data: (data) => data,
                                                  // if error, show unknown collection
                                                  error: (error, stackTrace) =>
                                                      context.loc
                                                          .unknownCollection,
                                                  loading: () =>
                                                      context.loc.loading,
                                                ))).name,
                                    chainConfig[tokenInfoData.chainId]!
                                        .networkName,
                                    DisplayLongStringWithCopy(
                                      string: BigInt.parse(
                                              chipInfo.chipEthereumAddress
                                                  .toString()
                                                  .substring(2),
                                              radix: 16)
                                          .toString(),
                                      maxLength: 8,
                                      iconSize: 20,
                                      textStyles: Theme.of(context)
                                          .textTheme
                                          .headlineSmall,
                                    )
                                  ]),
                            tokenInfoData.chainId == 0
                                ? Container()
                                : InfoKeyValues(keys: [
                                    context.loc.ownership,
                                  ], values: [
                                    activeOffers.when(
                                      data: (offers) => nftOwner.when(
                                        data: (nftOwnerData) {
                                          if (ref.read(userAddressProvider) ==
                                              zeroAddress) {
                                            return context.loc.unconfirmed;
                                          } else if (approval.value !=
                                                  zeroAddress &&
                                              approval.value != null) {
                                            return context.loc.transferred;
                                          } else if (connectedWallet ==
                                                  nftOwnerData ||
                                              offers.any((element) =>
                                                  element.sellerAddress
                                                      .toLowerCase() ==
                                                  connectedWallet.hex
                                                      .toLowerCase())) {
                                            return context.loc.confirmed;
                                          } else {
                                            return context.loc.unconfirmed;
                                          }
                                        },
                                        error: (e, s) => context.loc
                                            .nftDetailsErrorFetchingCertificateData,
                                        loading: () => context.loc.loading,
                                      ),
                                      error: (e, s) => context.loc
                                          .nftDetailsErrorFetchingCertificateData,
                                      loading: () => context.loc.loading,
                                    ),
                                  ]),
                            const SizedBox(
                              height: 20,
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: CustomRoundedButton(
                                onPressed: () {
                                  launchUrl(
                                    Uri.parse(getEnvCertificateUrl(
                                        chipInfo.chipEthereumAddress.hex)),
                                  );
                                },
                                text: context
                                    .loc.nftDetailsPageShowCertificateButton,
                              ),
                            )
                          ],
                        ));
                  },
                  loading: () => Container(),
                  error: (e, s) => Container(),
                ),
                DropdownContainer(
                  title: context.loc.externalLinks,
                  content: Column(children: [
                    CustomRoundedButton(text: context.loc.openWebLink, onPressed: () {
                      launchUrl(weblinkUrl);
                    }),
                    const SizedBox(height: 15),

                    CustomRoundedButton(
                      text: context.loc.showOnOpenSea,
                      onPressed: () => {
                        launchUrl(openseaUrl.asData!.value,
                            mode: LaunchMode.externalApplication)
                      },
                    ),
                    const SizedBox(height: 15),
                    dotenv.get('APP_ID') == 'ownerchip_infineon'
                        ? Container()
                        : CustomRoundedButton(
                            text: context.loc.showOnRarible,
                            onPressed: () => {
                              launchUrl(raribleUrl.asData!.value,
                                  mode: LaunchMode.externalApplication)
                            },
                          ),

                  ]),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  GridView _buildButtons(
    AsyncValue<EthereumAddress> nftOwner,
    EthereumAddress connectedWallet,
    AsyncValue<EthereumAddress> approval,
    AsyncValue<List<dynamic>?> voucherContractAndTwinNftOwner,
    BuildContext context,
    AsyncValue<List<ActiveOffer>> activeOffers,
    UserSession? userSession,
    AsyncValue<BlockchainCollectionList> relevantCollections,
    AsyncValue<TokenChainAndCollection> tokenInfo,
    ReownAppKitModal? wc,
    ChipInfoModel chipInfo,
    AsyncValue<EthereumAddress?> voucherContractAddress,
    AsyncValue<EthereumAddress?> vouchertokenOwner,
    AsyncValue<EthereumAddress> lastSellerAddress,
    AsyncValue<Uri> raribleUrl, {
    DigitalTwinMetadata? digitalTwinMetadata,
  }) {
    return GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 7 / 5,
          crossAxisSpacing: 16,
        ),
        children: [
          ...nftOwner.when<List<Widget>>(
            data: (nftOwnerData) => connectedWallet == nftOwnerData
                ? approval.when(
                    data: (approvalData) => approval.value == zeroAddress ||
                            approval.value == null
                        ? [
                            voucherContractAndTwinNftOwner.when<Widget?>(
                              data: (data) => data != null &&
                                      data[0] != null &&
                                      data[0] != zeroAddress &&
                                      data[1] == connectedWallet
                                  ? BigIconButton(
                                      text: context.loc.offerForSale,
                                      onPressed: () {
                                        navigateToOfferOnMPScreen(context);
                                      },
                                      icon: Icon(
                                        Icons.euro,
                                        size: 35,
                                        color:
                                            CustomColors(dotenv.get('APP_ID'))
                                                .primaryColor,
                                      ),
                                      height: 85,
                                    )
                                  : null,
                              error: (e, s) => null,
                              loading: () => null,
                            ),
                            BigIconButton(
                              text: context.loc.transfer,
                              onPressed: () => Navigator.pushNamed(
                                context,
                                TransferScreen.routeName,
                                arguments: TransferScreenArguments(
                                  digitalTwinMetadata: digitalTwinMetadata,
                                ),
                              ),
                              icon: Icon(
                                Icons.send,
                                size: 35,
                                color: CustomColors(dotenv.get('APP_ID'))
                                    .primaryColor,
                              ),
                              height: 85,
                            ),
                          ].where((e) => e != null).cast<Widget>().toList()
                        : [],
                    error: (e, s) => [],
                    loading: () => [],
                  )
                : [],
            error: (e, s) => [],
            loading: () => [],
          ),
          ...activeOffers
              .when<List<Widget?>>(
                data: (activeOffersData) {
                  if (activeOffersData.isEmpty) {
                    //TOKEN IS NOT FOR SALE
                    return nftOwner.when(
                        data: (nftOwnerData) {
                          if (connectedWallet == zeroAddress ||
                              userSession == null) {
                            //USER IS NOT CONNECTED
                            return [];
                          } else {
                            //USER IS CONNECTED
                            if (connectedWallet == nftOwnerData) {
                              //USER IS OWNER
                              return approval.when(
                                  data: (approvalData) {
                                    if (approvalData == zeroAddress) {
                                      //TOKEN IS NOT APPROVED / NOT READY TO BE CLAIMED BY NEW OWNER
                                      return relevantCollections.when(
                                          data: (relevantCollectionsData) {
                                            late Collection collection;
                                            if (relevantCollectionsData
                                                        .collections[
                                                    tokenInfo.value!.chainId] !=
                                                null) {
                                              // USER HAS MINTERROLE FOR SOME COLLECTION
                                              collection =
                                                  relevantCollectionsData
                                                      .collections[tokenInfo
                                                          .value!.chainId]!
                                                      .firstWhere(
                                                          (element) =>
                                                              element.id ==
                                                              tokenInfo.value!
                                                                  .collectionId,
                                                          orElse: () =>
                                                              Collection(
                                                                  zeroAddress,
                                                                  '',
                                                                  hasMinterRole:
                                                                      false));
                                            } else {
                                              //USER DOES NOT HAVE MINTERROLE ANYWHERE
                                              collection = Collection(
                                                  zeroAddress, '',
                                                  hasMinterRole: false);
                                            }
                                            if (collection.hasMinterRole! &&
                                                collection.id ==
                                                    tokenInfo
                                                        .value!.collectionId) {
                                              // USER HAS MINTER ROLE FOR THIS TOKENS COLLECTION
                                              return [
                                                BigIconButton(
                                                  text: context.loc.burnToken,
                                                  onPressed: () async {
                                                    final sig = ref.read(
                                                        chipSignatureDataProvider);
                                                    if (sig.tokenId !=
                                                        chipInfo.tokenId) {
                                                      final res =
                                                          await scanItem(
                                                        ref,
                                                        context,
                                                        navigateToResultPage:
                                                            false,
                                                      );

                                                      if (res == null) {
                                                        return;
                                                      }
                                                    }

                                                    fromCancelable(burnToken(
                                                      wc,
                                                      chipInfo.tokenId,
                                                      ref.read(
                                                          chipSignatureDataProvider),
                                                      connectedWallet,
                                                      digitalTwinMetadata:
                                                          digitalTwinMetadata,
                                                    ));
                                                  },
                                                  icon: Icon(
                                                    Icons.delete_outline,
                                                    size: 35,
                                                    color: CustomColors(dotenv
                                                            .get('APP_ID'))
                                                        .primaryColor,
                                                  ),
                                                  height: 85,
                                                )
                                              ];
                                            } else {
                                              // USER DOES NOT HAVE MINTER ROLE FOR THIS TOKENS COLLECTION
                                              return [];
                                            }
                                          },
                                          error: (e, s) => [],
                                          loading: () => []);
                                    } else {
                                      //TOKEN IS APPROVED / IS READY TO BE CLAIMED BY NEW OWNER
                                      return [];
                                    }
                                  },
                                  loading: () => [],
                                  error: (e, s) => []);
                            } else {
                              //USER IS NOT OWNER
                              return approval.when<List<Widget>>(
                                  data: (approvalData) {
                                    if (approvalData == zeroAddress) {
                                      //TOKEN IS NOT APPROVED / NOT READY TO BE CLAIMED
                                      return voucherContractAddress
                                          .when<List<Widget>>(
                                        data: (voucherContractData) {
                                          // VOUCHER CONTRACT EXISTS
                                          return vouchertokenOwner.when(
                                              data: (voucherTokenOwnerData) {
                                                if (voucherTokenOwnerData ==
                                                        connectedWallet &&
                                                    voucherContractData !=
                                                        null) {
                                                  //USER IS VOUCHER OWNER AND CAN REDEEM TWIN
                                                  return [
                                                    BigIconButton(
                                                      text: context
                                                          .loc.redeemToken,
                                                      onPressed: () async {
                                                        final sig = ref.read(
                                                            chipSignatureDataProvider);
                                                        if (sig.tokenId !=
                                                            chipInfo.tokenId) {
                                                          final res =
                                                              await scanItem(
                                                            ref,
                                                            context,
                                                            navigateToResultPage:
                                                                false,
                                                          );

                                                          if (res == null) {
                                                            return;
                                                          }
                                                        }
                                                        fromCancelable(
                                                            redeemTwinToken(
                                                                wc,
                                                                chipInfo
                                                                    .tokenId,
                                                                ref.read(
                                                                    chipSignatureDataProvider),
                                                                connectedWallet));
                                                      },
                                                      icon: Icon(
                                                        Icons.call_received,
                                                        size: 35,
                                                        color: CustomColors(
                                                                dotenv.get(
                                                                    'APP_ID'))
                                                            .primaryColor,
                                                      ),
                                                      height: 85,
                                                    )
                                                  ];
                                                } else {
                                                  //USER IS NOT VOUCHER OWNER
                                                  return tokenInfo.when(
                                                      data: (tokenInfoData) {
                                                        final EthereumAddress
                                                            controllerContractAddress =
                                                            EthereumAddress.fromHex(chainConfig[
                                                                    tokenInfoData
                                                                        .chainId]!
                                                                .controllerContract);
                                                        if (voucherTokenOwnerData ==
                                                                controllerContractAddress &&
                                                            nftOwnerData ==
                                                                controllerContractAddress &&
                                                            activeOffersData
                                                                .isEmpty) {
                                                          //ERROR HAPPENED WHEN TOKEN WAS OFFERED; NO OFFER IN BACKEND
                                                          return lastSellerAddress
                                                              .when(
                                                                  data:
                                                                      (lastSellerData) {
                                                                    if (lastSellerData ==
                                                                        connectedWallet) {
                                                                      return [];
                                                                    } else {
                                                                      return [];
                                                                    }
                                                                  },
                                                                  error:
                                                                      (e, s) =>
                                                                          [],
                                                                  loading: () =>
                                                                      []);
                                                        } else {
                                                          return [];
                                                        }
                                                      },
                                                      error: (e, s) => [],
                                                      loading: () => []);
                                                }
                                              },
                                              error: (e, s) => [],
                                              loading: () => []);
                                        },
                                        loading: () => [],
                                        error: (e, s) {
                                          return [];
                                        },
                                      );
                                    } else {
                                      //TOKEN IS APPROVED / IS READY TO BE CLAIMED
                                      return approval.when(
                                          data: (approvalData) {
                                            if (approvalData ==
                                                connectedWallet) {
                                              //USER IS APPROVED TO CLAIM
                                              return [];
                                            } else {
                                              //USER IS NOT APPROVED TO CLAIM
                                              return [];
                                            }
                                          },
                                          loading: () => [],
                                          error: (e, s) => []);
                                    }
                                  },
                                  loading: () => [],
                                  error: (e, s) => []);
                            }
                          }
                        },
                        loading: () => [],
                        error: (e, s) => []);
                  } else {
                    //TOKEN IS FOR SALE
                    return [
                      BigIconButton(
                        text: context.loc.buyOnRarible,
                        icon: Icon(
                          Icons.shopping_cart_outlined,
                          size: 35,
                          color:
                              CustomColors(dotenv.get('APP_ID')).primaryColor,
                        ),
                        onPressed: () => {
                          launchUrl(raribleUrl.asData!.value,
                              mode: LaunchMode.externalApplication)
                        },
                      ),
                      if (activeOffersData.isNotEmpty &&
                          EthereumAddress.fromHex(
                                  activeOffersData[0].sellerAddress) ==
                              connectedWallet)
                        //USER IS SELLER
                        BigIconButton(
                            icon: Icon(
                              Icons.close,
                              size: 35,
                              color: CustomColors(dotenv.get('APP_ID'))
                                  .primaryColor,
                            ),
                            text: context.loc.cancelOffer,
                            onPressed: () async {
                              final sig = ref.read(chipSignatureDataProvider);
                              if (sig.tokenId != chipInfo.tokenId) {
                                final res = await scanItem(
                                  ref,
                                  context,
                                  navigateToResultPage: false,
                                );

                                if (res == null) {
                                  return;
                                }
                              }

                              fromCancelable(
                                cancelOffer(
                                    wc,
                                    chipInfo.tokenId,
                                    ref.read(chipSignatureDataProvider),
                                    connectedWallet),
                              );
                            })
                    ];
                  }
                },
                loading: () => [],
                error: (e, s) => [],
              )
              .where((e) => e != null)
              .cast<Widget>(),
        ]);
  }
}

void navigateToOfferOnMPScreen(BuildContext context) {
  if (dotenv.get('APP_ID') == 'ownerchip_infineon') {
    showCustomPopup(
        context,
        context.loc.offerOnMpDiscoverDialogTitle,
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            context.loc.offerOnMpDiscoveryDialogMessage,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ]));
  } else {
    Navigator.pushNamed(context, OfferOnMPScreen.routeName);
  }
}
