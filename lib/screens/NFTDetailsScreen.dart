//import packages
import 'package:flutter/material.dart';
import 'package:ownerchip_whitelabel/screens/ListAttachmentsScreen.dart';
import 'package:ownerchip_whitelabel/screens/OfferOnMPScreen.dart';
import 'package:ownerchip_whitelabel/screens/TransferScreen.dart';
import 'package:ownerchip_whitelabel/services/backend.services.dart';
import 'package:ownerchip_whitelabel/services/providers/collectionsData.dart';
import 'package:ownerchip_whitelabel/services/providers/urlData.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/themes/fontSpecs.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:ownerchip_whitelabel/widgets/ui/RefreshMetadataButton.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web3dart/web3dart.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/services/providers/chipData.dart';
import 'package:ownerchip_whitelabel/services/providers/nftData.dart';
import 'package:ownerchip_whitelabel/services/providers/attachmentsData.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';

//import widgets
import 'package:ownerchip_whitelabel/widgets/ui/CustomAppBar.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomCard.dart';
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomImage.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/InfoKeyValues.dart';
import 'package:ownerchip_whitelabel/widgets/ui/DropdownContainer.dart';
import 'package:ownerchip_whitelabel/widgets/ui/ChipInfo.dart';
import 'package:ownerchip_whitelabel/widgets/ui/AttachmentBox.dart';
import 'package:ownerchip_whitelabel/widgets/ui/BigIconButton.dart';

//import misc
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/config/chains.dart';
import 'package:ownerchip_whitelabel/config/collections.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';

class NFTDetailsScreen extends ConsumerStatefulWidget {
  const NFTDetailsScreen({super.key});

  static const routeName = '/nft-details';

  @override
  _NFTDetailsScreen createState() => _NFTDetailsScreen();
}

class _NFTDetailsScreen extends ConsumerState<NFTDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final session = ref.watch(userSessionProvider);
    final ChipInfoModel chipInfo = ref.watch(chipInfoProvider);
    final AsyncValue<Map<String, dynamic>> nftMetadata =
        ref.watch(nftMetadataProvider(chipInfo.tokenId));
    final AsyncValue<String> nftImageUri =
        ref.watch(nftImageProvider(chipInfo.tokenId));
    final AsyncValue<TokenChainAndCollection> tokenInfo =
        ref.watch(findTokenProvider(chipInfo.tokenId));
    final wc = ref.watch(wcProvider);
    final AsyncValue<Uri> raribleUrl = ref.watch(raribleUrlProvider);
    final AsyncValue<Uri> openseaUrl = ref.watch(openseaUrlProvider);
    final AsyncValue<Uri> blockchainExplorerUrl =
        ref.watch(blockchainExplorerUrlProvider);
    final AsyncValue<String> contractName = ref.watch(contractNameProvider);
    final AsyncValue<EthereumAddress> nftOwner = ref.watch(nftOwnerProvider);
    final EthereumAddress connectedWallet = ref.watch(userAddressProvider);
    final AsyncValue<List<Attachment>> fetchedAttachments = ref.watch(
        fetchAttachmentsProvider); //Trigger loading of attachments, which are saved to localAttachmentsProvider
    List<Attachment> attachments = ref.watch(localAttachmentsProvider);
    List<Attachment> ownerAttachments = ref.watch(ownerAttachmentsProvider);
    List<Attachment> creatorAttachments = ref.watch(creatorAttachmentsProvider);
    final AsyncValue<List?> voucherContractAndTwinNftOwner =
        ref.watch(voucherContractAndTwinNftOwnerProvider);
    final AsyncValue<EthereumAddress> approval = ref.watch(nftApprovalProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        text: context.loc.nftDetails,
      ),
      body: ScreenBodyLayout(children: [
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
                      data: (data) => Text(data['name'],
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge!
                              .copyWith(
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
            nftOwner.when(
              data: (nftOwnerData) => connectedWallet == nftOwnerData
                  ? approval.when(
                      data: (approvalData) => approval.value == zeroAddress ||
                              approval.value == null
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                voucherContractAndTwinNftOwner.when(
                                  data: (data) => data != null &&
                                          data[0] != null &&
                                          data[1] == connectedWallet
                                      ? Expanded(
                                          flex: 1,
                                          child: BigIconButton(
                                            text: context.loc.offerForSale,
                                            onPressed: () =>
                                                Navigator.pushNamed(context,
                                                    OfferOnMPScreen.routeName),
                                            icon: Icon(
                                              Icons.euro,
                                              size: 35,
                                              color: CustomColors(
                                                      dotenv.get('APP_ID'))
                                                  .primaryColor,
                                            ),
                                            height: 85,
                                          ),
                                        )
                                      : Container(),
                                  error: (e, s) => Container(),
                                  loading: () => Container(),
                                ),
                                voucherContractAndTwinNftOwner.when(
                                  data: (data) => data != null &&
                                          data[0] != null &&
                                          data[1] == connectedWallet
                                      ? const SizedBox(
                                          width: 10,
                                        )
                                      : Container(),
                                  error: (e, s) => Container(),
                                  loading: () => Container(),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: BigIconButton(
                                    text: context.loc.transfer,
                                    onPressed: () => Navigator.pushNamed(
                                        context, TransferScreen.routeName),
                                    icon: Icon(
                                      Icons.send,
                                      size: 35,
                                      color: CustomColors(dotenv.get('APP_ID'))
                                          .primaryColor,
                                    ),
                                    height: 85,
                                  ),
                                )
                              ],
                            )
                          : Container(),
                      error: (e, s) => Container(),
                      loading: () => Container(),
                    )
                  : Container(),
              error: (e, s) => Container(),
              loading: () => Container(),
            ),

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
                                  if (!await launchUrl(Uri.parse(link.url))) {
                                    throw Exception(
                                        'Could not launch ${link.url}');
                                  }
                                  sendAnalyticsTrace(session?.sessionId ?? "",
                                      "", "DESCRIPTION_VIEW",
                                      tags: {
                                        'connectedWallet': connectedWallet.hex,
                                        'chipWallet':
                                            convertTokenIdToEthereumAddress(ref
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
            (attachments.isNotEmpty ||
                    (nftOwner.hasValue && connectedWallet == nftOwner.value))
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
                                          sendAnalyticsTrace(
                                              session?.sessionId ?? "",
                                              e.backendUuid,
                                              "ATTACHMENT_VIEW",
                                              tags: {
                                                'connectedWallet':
                                                    connectedWallet.hex,
                                                'chipWallet':
                                                    convertTokenIdToEthereumAddress(
                                                        ref
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
                                          sendAnalyticsTrace(
                                              session?.sessionId ?? "",
                                              e.backendUuid,
                                              "ATTACHMENT_VIEW",
                                              tags: {
                                                'connectedWallet':
                                                    connectedWallet.hex,
                                                'chipWallet':
                                                    convertTokenIdToEthereumAddress(
                                                        ref
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
                          context.loc.ownership,
                        ], values: [
                          // authenticity
                          tokenInfo.when(
                            data: ((data) => data.collectionId == zeroAddress
                                ? context.loc.unconfirmed
                                : context.loc.confirmed),
                            error: (e, s) => context.loc.confirmed,
                            loading: () => context.loc.loading,
                          ),
                          // ownership

                          nftOwner.when(
                            data: ((nftOwnerData) => ref
                                        .read(userAddressProvider) ==
                                    zeroAddress
                                ?
                                //NFT owner exists and wallet is NOT connected
                                context.loc.unconfirmed
                                : connectedWallet == nftOwnerData
                                    ?
                                    //NFT owner exists and wallet is connected and wallet is owner
                                    context.loc.confirmed
                                    :
                                    //NFT owner exists and wallet is connected and wallet is NOT owner
                                    context.loc.unconfirmed),
                            error: (e, s) => context.loc.ownerError,
                            loading: () => context.loc.loading,
                          ),
                        ]),
                        const SizedBox(height: 20),
                        //if tokenInfo could not be loaded and hence chainId is zero, display empty container
                        tokenInfoData.chainId == 0
                            ? Container()
                            : InfoKeyValues(keys: const [
                                "Collection",
                                "Blockchain",
                              ], values: [
                                // first, try to find collection in collections list
                                allCollections
                                    .collections[tokenInfoData.chainId]!
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
                                                  context.loc.unknownCollection,
                                              loading: () =>
                                                  context.loc.loading,
                                            ))).name,
                                chainConfig[tokenInfoData.chainId]!.networkName,
                              ]),
                        //spacing
                        const SizedBox(height: 13),
                        ChipInfo(
                          tokenId: BigInt.parse(
                              chipInfo.chipEthereumAddress
                                  .toString()
                                  .substring(2),
                              radix: 16),
                        ),
                        const SizedBox(height: 20),
                        CustomRoundedButton(
                          text: context.loc.showOnExplorer,
                          onPressed: () => {
                            launchUrl(blockchainExplorerUrl.asData!.value,
                                mode: LaunchMode.externalApplication)
                          },
                        ),
                      ],
                    ));
              },
              loading: () => Container(),
              error: (e, s) => Container(),
            ),
            DropdownContainer(
              title: context.loc.externalLinks,
              content: Column(children: [
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
        )
      ]),
    );
  }
}
