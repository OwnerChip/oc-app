//import packages
import 'package:flutter/material.dart';
import 'package:ownerchip_whitelabel/themes/fontSpecs.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/services/providers.service.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';

//import widgets
import 'package:ownerchip_whitelabel/widgets/ui/CustomAppBar.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomCard.dart';
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomImage.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/InfoKeyValues.dart';
import 'package:ownerchip_whitelabel/widgets/ui/returnSnackBarWidget.dart';

//import misc
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/config/chains.dart';
import 'package:ownerchip_whitelabel/config/collections.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';

class NFTDetailsScreen extends ConsumerStatefulWidget {
  const NFTDetailsScreen({super.key});

  static const routeName = '/nft-details';

  @override
  _NFTDetailsScreen createState() => _NFTDetailsScreen();
}

class _NFTDetailsScreen extends ConsumerState<NFTDetailsScreen> {
  bool showDescription = true;

  void toggleDescription() {
    setState(() {
      showDescription = !showDescription;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ChipInfoModel chipInfo = ref.watch(chipInfoProvider);
    final AsyncValue<Map<String, dynamic>> nftMetadata =
        ref.watch(nftMetadataProvider(chipInfo.tokenId));
    final AsyncValue<String> nftImageUri =
        ref.watch(nftImageProvider(chipInfo.tokenId));
    final AsyncValue<TokenInfoObject> tokenInfo =
        ref.watch(findTokenProvider(chipInfo.tokenId));
    WalletConnect wc = ref.watch(walletConnectProvider);
    final AsyncValue<Uri> raribleUrl = ref.watch(raribleUrlProvider);
    final AsyncValue<Uri> openseaUrl = ref.watch(openseaUrlProvider);
    final AsyncValue<Uri> blockchainExplorerUrl =
        ref.watch(blockchainExplorerUrlProvider);
    final AsyncValue<String> contractName = ref.watch(contractNameProvider);
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
                // ScaffoldMessenger.of(context).showSnackBar(
                //   returnSnackBarWidget(context.loc.errorHeadingSnackBar,
                //       context.loc.loadingNFTDataError, 'error'),
                // );
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
                            fontSize: CustomFonts(dotenv.get('STYLE_ID'))
                                .metadataNameFontSize,
                            fontWeight: CustomFonts(dotenv.get('STYLE_ID'))
                                .metadataNameFontWeight))),

                //show traits button
                nftMetadata.when(
                  loading: () => Container(),
                  data: (data) => data['traits'] != null &&
                          data['traits']!.isNotEmpty
                      ? CustomRoundedButton(
                          height: 30,
                          width: null,
                          textStyle: Theme.of(context)
                              .textTheme
                              .bodyLarge!
                              .copyWith(
                                  color: CustomColors(dotenv.get('STYLE_ID'))
                                      .customRoundedButtonColor,
                                  fontSize: CustomFonts(dotenv.get('STYLE_ID'))
                                          .bodyText2FontSize /
                                      1.3),
                          text: showDescription
                              ? context.loc.showTraits
                              : context.loc.showDescription,
                          onPressed: () => toggleDescription())
                      : Container(),
                  error: (e, s) => Container(),
                )
              ],
            ),
            Divider(
              color: Theme.of(context).primaryColor,
              height: 20,
              thickness: 1,
              indent: 0,
              endIndent: 0,
            ),
            nftMetadata.when(
                data: (data) => Column(
                      children: [
                        showDescription
                            ? Align(
                                alignment: Alignment.centerLeft,
                                child: Text(data['description'] ?? '',
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                        // color: Theme.of(context).primaryColor,
                                        fontSize:
                                            CustomFonts(dotenv.get('STYLE_ID'))
                                                .metadataDescriptionFontSize,
                                        fontWeight: CustomFonts(
                                                dotenv.get('STYLE_ID'))
                                            .metadataDescriptionFontWeight)),
                              )
                            : Align(
                                alignment: Alignment.centerLeft,
                                child: Column(children: <Widget>[
                                  ...data['traits']
                                      .map((e) => Row(
                                            children: [
                                              Text(e['trait_type'] + ': ',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium!
                                                      .copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: CustomFonts(
                                                                dotenv.get(
                                                                    'STYLE_ID'))
                                                            .metadataDescriptionFontSize,
                                                      )),
                                              Text(e['value'],
                                                  style: TextStyle(
                                                    fontSize: CustomFonts(dotenv
                                                            .get('STYLE_ID'))
                                                        .metadataDescriptionFontSize,
                                                  )),
                                            ],
                                          ))
                                      .toList()
                                ])),
                        Divider(
                          color: Theme.of(context).primaryColor,
                          height: 20,
                          thickness: 1,
                          indent: 0,
                          endIndent: 0,
                        ),
                        tokenInfo.when(
                          data: (data) => InfoKeyValues(keys: const [
                            "Collection",
                            "Blockchain"
                          ], values: [
                            Collections('all')
                                .collections[data.chainId]!
                                .firstWhere((collection) {
                              return collection['id'] == data.collectionId;
                            },
                                    orElse: () => {
                                          'name': contractName.when(
                                            data: (data) => data,
                                            error: (error, stackTrace) =>
                                                context.loc.unknownCollection,
                                            loading: () => context.loc.loading,
                                          )
                                        })['name'],
                            chainConfig[data.chainId]!.networkName,
                          ]),
                          loading: () => Container(),
                          error: (e, s) => Container(),
                        )
                      ],
                    ),
                error: (e, s) => Container(),
                loading: () => Container()),
            const SizedBox(height: 20),
            CustomRoundedButton(
              text: context.loc.showOnExplorer,
              onPressed: () => {
                launchUrl(blockchainExplorerUrl.asData!.value,
                    mode: LaunchMode.externalApplication)
              },
            ),
            const SizedBox(height: 15),
            CustomRoundedButton(
              text: context.loc.showOnOpenSea,
              onPressed: () => {
                launchUrl(openseaUrl.asData!.value,
                    mode: LaunchMode.externalApplication)
              },
            ),
            const SizedBox(height: 15),
            dotenv.get('STYLE_ID') == 'ownerchip_infineon'
                ? Container()
                : CustomRoundedButton(
                    text: context.loc.showOnRarible,
                    onPressed: () => {
                      launchUrl(raribleUrl.asData!.value,
                          mode: LaunchMode.externalApplication)
                    },
                  ),
          ],
        )
      ]),
    );
  }
}
