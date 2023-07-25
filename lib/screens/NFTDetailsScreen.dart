//import packages
import 'package:flutter/material.dart';
import 'package:ownerchip_whitelabel/themes/fontSpecs.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/services/providers.service.dart';
import 'package:web3dart/web3dart.dart';
import 'package:flutter_linkify/flutter_linkify.dart';

//import widgets
import 'package:ownerchip_whitelabel/widgets/ui/CustomAppBar.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomCard.dart';
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomImage.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/InfoKeyValues.dart';
import 'package:ownerchip_whitelabel/widgets/ui/DropdownContainer.dart';
import 'package:ownerchip_whitelabel/widgets/ui/ChipInfo.dart';

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
    final ChipInfoModel chipInfo = ref.watch(chipInfoProvider);
    final AsyncValue<Map<String, dynamic>> nftMetadata =
        ref.watch(nftMetadataProvider(chipInfo.tokenId));
    final AsyncValue<String> nftImageUri =
        ref.watch(nftImageProvider(chipInfo.tokenId));
    final AsyncValue<TokenInfoObject> tokenInfo =
        ref.watch(findTokenProvider(chipInfo.tokenId));
    final wc = ref.watch(wcProvider);
    final AsyncValue<Uri> raribleUrl = ref.watch(raribleUrlProvider);
    final AsyncValue<Uri> openseaUrl = ref.watch(openseaUrlProvider);
    final AsyncValue<Uri> blockchainExplorerUrl =
        ref.watch(blockchainExplorerUrlProvider);
    final AsyncValue<String> contractName = ref.watch(contractNameProvider);

    final AsyncValue<EthereumAddress> nftOwner = ref.watch(nftOwnerProvider);

    final EthereumAddress connectedWallet = ref.watch(userAddressProvider);

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
                    child: Text(
                        nftMetadata.when(
                            loading: () => context.loc.loading,
                            data: (data) => data['name'],
                            error: (e, s) => context.loc.loadingNFTDataError),
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            fontSize: CustomFonts(dotenv.get('APP_ID'))
                                .metadataNameFontSize,
                            fontWeight: CustomFonts(dotenv.get('APP_ID'))
                                .metadataNameFontWeight))),
              ],
            ),
            Divider(
              color: Theme.of(context).primaryColor,
              height: 20,
              thickness: 1,
              indent: 0,
              endIndent: 0,
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

            /*** DIGITAL TWIN ***/
            tokenInfo.when(
              data: (data) => DropdownContainer(
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
                          data: ((data) => wc!.getActiveSessions().isEmpty
                              ?
                              //NFT owner exists and wallet is NOT connected
                              context.loc.unconfirmed
                              : connectedWallet == data
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
                      InfoKeyValues(keys: const [
                        "Collection",
                        "Blockchain",
                      ], values: [
                        // first, try to find collection in collections list
                        allCollections.collections[data.chainId]!.firstWhere(
                            (collection) {
                          return collection.id == data.collectionId;
                        },
                            // if not found, check chain data
                            orElse: () => Collection(
                                data.collectionId,
                                contractName.when(
                                  data: (data) => data,
                                  // if error, show unknown collection
                                  error: (error, stackTrace) =>
                                      context.loc.unknownCollection,
                                  loading: () => context.loc.loading,
                                ))).name,
                        chainConfig[data.chainId]!.networkName,
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
                  )),
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
