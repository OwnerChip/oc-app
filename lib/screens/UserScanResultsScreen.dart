import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../utils/localization.helper.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/services/providers.service.dart';

//local imports
import 'NFTDetailsScreen.dart';
import '../widgets/ui/CustomAppBar.dart';
import '../utils/navigation.arguments.dart';
import '../widgets/ui/ChipInfo.dart';
import '../widgets/ui/CustomCard.dart';
import '../widgets/layout/ScreenBodyLayout.dart';
import '../widgets/ui/CustomImage.dart';
import '../widgets/ui/CustomRoundedButton.dart';
import 'package:ownerchip_whitelabel/services/walletconnect.services.dart';
import 'package:ownerchip_whitelabel/config/chains.dart';

class UserScanResultsScreen extends ConsumerStatefulWidget {
  const UserScanResultsScreen({super.key});

  static const routeName = '/user-scan-results';

  @override
  _UserScanResultsScreenState createState() => _UserScanResultsScreenState();
}

class _UserScanResultsScreenState extends ConsumerState<UserScanResultsScreen> {
  bool loadingImage = true;

  Future<void> launchWallet() async {
    await launchUrlString('wc:', mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final chipInfo = ref.watch(chipInfoProvider);
    final nftImageUri = ref.watch(nftImageProvider(chipInfo.tokenId));
    final nftOwner = ref.watch(nftOwnerProvider);
    WalletConnect wc = ref.watch(walletConnectProvider);

    final connectedWallet = wc.session.accounts.length > 0
        ? wc.session.accounts[0].toLowerCase()
        : '';

    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: CustomAppBar(
          text: context.loc.tapResults,
          connectedWalletAddress:
              wc.connected ? null : connectedWallet, //wallet adresse
        ),
        body: ScreenBodyLayout(children: [
          Stack(
            alignment: Alignment.topCenter,
            children: [
              CustomCard(
                  margin: EdgeInsets.only(top: 70),
                  width: double.infinity,
                  children: [
                    SizedBox(height: 100),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        //HEADER BUTTON
                        nftOwner.when(
                            error: (e, s) => Container(),
                            loading: () => Text(context.loc.loading,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headline1),
                            data: (data) => CustomRoundedButton(
                                width: 250,
                                text: context.loc.viewNftDetails,
                                onPressed: () {
                                  print(context);
                                  Navigator.of(context)
                                      .pushNamed(NFTDetailsScreen.routeName);
                                })),
                        const SizedBox(height: 15),
                      ],
                    ),
                    const SizedBox(height: 15),
                    CustomCard(
                        color: CustomColors(dotenv.get('APP_ID'))
                            .scaffoldBackgroundColor,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(context.loc.ownershipCheck,
                                  style: Theme.of(context).textTheme.headline4),

                              //OWNERSHIP CHECK ICON
                              nftOwner.when(
                                data: ((data) => !wc.connected
                                    ?
                                    //NFT owner exists and wallet is NOT connected
                                    SvgPicture.asset(
                                        "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/triangle_small.svg")
                                    : connectedWallet == data.toString()
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
                                loading: () => CircularProgressIndicator(),
                              )
                            ],
                          ),
                          const SizedBox(height: 15),

                          //OWNERSHIP CHECK BODY
                          nftOwner.when(
                              data: (data) => !wc.connected
                                  ?
                                  //NFT owner exists and wallet is NOT connected
                                  Column(
                                      children: [
                                        Text(context.loc.noWalletConnected,
                                            style: Theme.of(context)
                                                .textTheme
                                                .headline5),
                                        const SizedBox(height: 10),
                                        CustomRoundedButton(
                                            text: context.loc.connectWallet,
                                            onPressed: (() => {
                                                  startWalletConnection(
                                                      context, wc)
                                                }))
                                      ],
                                    )
                                  : connectedWallet == data.toString()
                                      ?
                                      //NFT owner exists and wallet is connected and wallet is owner
                                      Text(context.loc.youAreNftOwner,
                                          style: Theme.of(context)
                                              .textTheme
                                              .headline5)
                                      :
                                      //NFT owner exists and wallet is connected and wallet is NOT owner
                                      Text(context.loc.youAreNotNftOwner,
                                          style: Theme.of(context)
                                              .textTheme
                                              .headline5),
                              error: (e, s) => Text(
                                  context.loc.youAreNotNftOwner,
                                  style: Theme.of(context).textTheme.headline5),
                              loading: () => const CircularProgressIndicator()),
                        ]),
                    const SizedBox(height: 20),
                    CustomCard(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        children: [
                          Row(
                            //space between
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(context.loc.nfcCheck,
                                  style: Theme.of(context).textTheme.headline4),
                              //checkmark icon
                              SvgPicture.asset(
                                  "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/check.svg"),
                            ],
                          ),
                          const SizedBox(height: 15),
                          ChipInfo(
                              tokenId: chipInfo.chipIsInitialized
                                  ? chipInfo.tokenId
                                  : null,
                              chipName: 'Infineon Secora',
                              walletAddress: chipInfo.chipEthereumAddress)
                        ])
                  ]),
              nftImageUri.when(
                loading: () => CustomImage(
                  width: 130,
                  loading: true,
                ),
                error: (e, s) => CustomImage(
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
        ]));
  }
}
