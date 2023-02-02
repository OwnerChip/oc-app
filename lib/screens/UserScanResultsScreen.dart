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
                        //Header Title

                        nftOwner.when(
                          error: (e, s) => Text(context.loc.ownerError,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headline1),
                          loading: () => Text(context.loc.loading,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headline1),
                          data: (data) => wc.connected &&
                                  connectedWallet == nftOwner.toString()
                              ?
                              //connected wallet is owner
                              Text(context.loc.congrats,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.headline1)
                              : chipInfo.chipIsInitialized
                                  ? Text(context.loc.authentic,
                                      textAlign: TextAlign.center,
                                      style:
                                          Theme.of(context).textTheme.headline1)
                                  :
                                  //connected wallet is not owner
                                  Text(context.loc.whoops,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headline1),
                        ),
                        SizedBox(height: 15),
                        //Header Body Text
                        nftOwner.when(
                            error: (e, s) => Container(),
                            loading: () => Container(),
                            data: (data) => !chipInfo.chipIsInitialized
                                ?
                                //chip is not initialized aka NFT does not exist
                                Text(context.loc.nftNotFound,
                                    textAlign: TextAlign.center,
                                    style:
                                        Theme.of(context).textTheme.headline5)
                                : wc.connected &&
                                        connectedWallet == nftOwner.toString()
                                    ?
                                    //chip is initialized and wallet is connected
                                    Text(context.loc.authenticityNftFound,
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline5)
                                    :
                                    //chip is initialized and wallet is NOT connected
                                    Container())
                      ],
                    ),
                    SizedBox(height: 15),
                    CustomCard(
                        color: CustomColors(dotenv.get('APP_ID'))
                            .scaffoldBackgroundColor,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(context.loc.authenticityCheck,
                                  style: Theme.of(context).textTheme.headline4),

                              //Ownerchip Check Icon
                              !chipInfo.chipIsInitialized
                                  ? //chip not initialized aka no NFT exists
                                  SvgPicture.asset(
                                      "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/alert_cross.svg")
                                  : !wc.connected
                                      ?
                                      //chip is initialized and wallet is NOT connected
                                      SvgPicture.asset(
                                          "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/triangle_small.svg")
                                      : connectedWallet == nftOwner.toString()
                                          ?
                                          //chip is initialized and wallet is connected and wallet is owner
                                          SvgPicture.asset(
                                              "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/check.svg")
                                          :
                                          //chip is initialized and wallet is connected and wallet is NOT owner
                                          SvgPicture.asset(
                                              "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/alert_cross.svg")
                            ],
                          ),
                          //spacing
                          SizedBox(height: 15),

                          //Ownerchip Check Icon
                          !chipInfo.chipIsInitialized
                              ? //chip not initialized aka no NFT exists
                              Text(context.loc.ownershipCouldNotBeVerified,
                                  style: Theme.of(context).textTheme.headline5)
                              : !wc.connected
                                  ?
                                  //chip is initialized and wallet is NOT connected
                                  Text(context.loc.noWalletConnected,
                                      style:
                                          Theme.of(context).textTheme.headline5)
                                  : connectedWallet == nftOwner.toString()
                                      ?
                                      //chip is initialized and wallet is connected and wallet is owner
                                      Text(context.loc.youAreNftOwner,
                                          style: Theme.of(context)
                                              .textTheme
                                              .headline5)
                                      :
                                      //chip is initialized and wallet is connected and wallet is NOT owner
                                      Text(context.loc.youAreNotNftOwner,
                                          style: Theme.of(context)
                                              .textTheme
                                              .headline5),

                          SizedBox(height: 15),

                          //Ownerchip Check Button
                          !chipInfo.chipIsInitialized
                              ?
                              //chip is NOT initialized
                              Container()
                              : !wc.connected
                                  ?
                                  //chip is initialized and wallet is NOT connected
                                  CustomRoundedButton(
                                      text: context.loc.connectWallet,
                                      onPressed: (() =>
                                          {startWalletConnection(context, wc)}))
                                  :
                                  //chip is initialized and wallet is connected
                                  CustomRoundedButton(
                                      text: context.loc.viewNftDetails,
                                      onPressed: () {
                                        print(context);
                                        Navigator.of(context).pushNamed(
                                            NFTDetailsScreen.routeName);
                                      }),
                        ]),
                    //spacing
                    SizedBox(height: 20),
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
                          //spacing
                          SizedBox(height: 15),
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
