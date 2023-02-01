import 'package:flutter/material.dart';
import 'package:ownerchip_whitelabel/themes/fontSpecs.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/localization.helper.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/services/providers.service.dart';

//web3 imports
import 'package:walletconnect_dart/walletconnect_dart.dart';

//local imports
import '../widgets/ui/CustomAppBar.dart';
import '../utils/navigation.arguments.dart';
import '../services/url_generator.service.dart';
import '../widgets/ui/CustomCard.dart';
import '../widgets/layout/ScreenBodyLayout.dart';
import '../widgets/ui/CustomImage.dart';
import '../widgets/ui/CustomRoundedButton.dart';
import '../themes/colorSpecs.dart';

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
    final NFTDetailsScreenArguments navArgs =
        ModalRoute.of(context)!.settings.arguments as NFTDetailsScreenArguments;
    final tokenId = ref.watch(tokenIdProvider);
    final nftMetadata = ref.watch(nftMetadataProvider(tokenId));
    final nftImageUri = ref.watch(nftImageProvider(tokenId));
    WalletConnect wc = ref.watch(walletConnectProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        text: context.loc.nftDetails,
        connectedWalletAddress: wc.session.accounts.isEmpty == true
            ? null
            : wc.session.accounts[0].toLowerCase(),
      ),
      body: ScreenBodyLayout(children: [
        CustomCard(
          children: [
            nftImageUri.when(
              loading: () => CustomImage(
                loading: true,
                tokenId: tokenId,
              ),
              error: (e, s) => CustomImage(
                loading: false,
                tokenId: tokenId,
              ),
              data: (data) => CustomImage(
                loading: false,
                imagePath: data,
                tokenId: tokenId,
              ),
            ),
            //spacing
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    nftMetadata.when(
                        loading: () => context.loc.loading,
                        data: (data) => data['name'],
                        error: (e, s) => context.loc.loading),
                    style: Theme.of(context).textTheme.bodyText1!.copyWith(
                        fontSize: CustomFonts(dotenv.get('APP_ID'))
                            .MetadataNameFontSize,
                        fontWeight: CustomFonts(dotenv.get('APP_ID'))
                            .MetadataNameFontWeight)),

                //show traits button
                nftMetadata.when(
                  loading: () => Container(),
                  data: (data) => data['traits'] != null &&
                          data['traits']!.isNotEmpty
                      ? CustomRoundedButton(
                          height: 30,
                          width: 170,
                          textStyle: Theme.of(context)
                              .textTheme
                              .bodyText1!
                              .copyWith(
                                  color: CustomColors(dotenv.get('APP_ID'))
                                      .customRoundedButtonColor,
                                  fontSize: CustomFonts(dotenv.get('APP_ID'))
                                          .bodyText2FontSize /
                                      1.3),
                          // TODO: reduze size / change layout?
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
                data: (data) => showDescription
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                            data['description'] ??
                                '${context.loc.loadingData}...',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                                // color: Theme.of(context).primaryColor,
                                fontSize: CustomFonts(dotenv.get('APP_ID'))
                                    .MetadataDescriptionFontSize,
                                fontWeight: CustomFonts(dotenv.get('APP_ID'))
                                    .MetadataDescriptionFontWeight)),
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
                                              .bodyText2!
                                              .copyWith(
                                                fontWeight: FontWeight.bold,
                                                fontSize: CustomFonts(
                                                        dotenv.get('APP_ID'))
                                                    .MetadataDescriptionFontSize,
                                              )),
                                      Text(e['value'],
                                          style: TextStyle(
                                            fontSize: CustomFonts(
                                                    dotenv.get('APP_ID'))
                                                .MetadataDescriptionFontSize,
                                          )),
                                    ],
                                  ))
                              .toList()
                        ])),
                error: (e, s) => Container(),
                loading: () => Container()),

            //spacing
            SizedBox(height: 20),
            CustomRoundedButton(
              text: context.loc.showOnExplorer,
              onPressed: () => {
                launchUrl(
                    generateBlockchainExplorerTokenDetailsUrl(
                        tokenId.toString()),
                    mode: LaunchMode.externalApplication)
              },
            ),
            const SizedBox(height: 15),
            CustomRoundedButton(
              text: context.loc.showOnOpenSea,
              onPressed: () => {
                launchUrl(generateOpenSeaTokenDetailsUrl(tokenId.toString()),
                    mode: LaunchMode.externalApplication)
              },
            ),
          ],
        )
      ]),
    );
  }
}
