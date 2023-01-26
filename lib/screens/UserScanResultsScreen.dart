import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../utils/localization.helper.dart';
import 'package:web3dart/crypto.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/utils/providers.service.dart';

//local imports
import 'NFTDetailsScreen.dart';
import '../widgets/CustomAppBar.dart';
import '../utils/navigation_arguments.dart';
import '../widgets/ChipInfo.dart';
import '../widgets/CustomCard.dart';
import '../widgets/ScreenBodyLayout.dart';
import '../widgets/CustomImage.dart';
import '../widgets/CustomRoundedButton.dart';
import '../widgets/returnSnackBarWidget.dart';
import '../utils/ipfs.services.dart';
import '../utils/web3.services.dart';
import '../widgets/LoadingOverlay.dart';
import 'package:ownerchip_whitelabel/utils/walletConnect.dart';

class UserScanResultsScreen extends ConsumerStatefulWidget {
  const UserScanResultsScreen({super.key});

  static const routeName = '/user-scan-results';

  @override
  _UserScanResultsScreenState createState() => _UserScanResultsScreenState();
}

class _UserScanResultsScreenState extends ConsumerState<UserScanResultsScreen> {
  String imagePath = "";
  String imageUri = "";
  Map<String, dynamic> metadata = {};
  bool loadingImage = true;

  // get the metadata.json file from IPFS associated with a token
  Future<Map<String, dynamic>> _fetchMetadata(BigInt tokenId) async {
    Map<String, dynamic> result = {};
    try {
      // get IPFS CID
      String tokenUri = await getTokenUri(tokenId);

      // fetch metadata json
      String jsonCid = getCidFromIpfsLink(tokenUri);
      final Directory directory = Directory.systemTemp;
      File jsonFile = File("${directory.path}/$jsonCid.metadata.json");
      await downloadMetadataFileFromIPFS(jsonCid, jsonFile.path, false);

      // read metadata json
      final String res = await jsonFile.readAsString();
      metadata = Map<String, dynamic>.from(json.decode(res));
      result = metadata;
    } catch (e) {
      print("error $e");
      // throw Exception("Error fetching metadata: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        returnSnackBarWidget(context.loc.errorHeadingSnackBar,
            context.loc.loadingNFTDataError, 'error'),
      );
    }
    return result;
  }

  // get the path of the associated image locally if available OR from IPFS if not
  Future<void> _fetchImage(
      String imgPath, Future<Map<String, dynamic>> meta) async {
    try {
      setState(() {
        loadingImage = true;
      });
      if (imgPath != "") {
        metadata = await meta;
        imagePath = imgPath;
      } else {
        Map<String, dynamic> metaSync = await meta;
        if (metaSync.containsKey("image") && metaSync['image']!.isNotEmpty) {
          String imageCid = getCidFromIpfsLink(metaSync['image']!);
          Map<String, String> result =
              await downloadImageFileFromIPFS(imageCid);
          imagePath = result['imagePath']!;
          imageUri = result['imageUri']!;
        }
      }
      // updateScreen
      setState(() {
        metadata;
        imagePath;
        loadingImage = false;
      });
    } catch (e) {
      print("error fetching image: $e");
      setState(() {
        loadingImage = true;
        imageUri = "";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        returnSnackBarWidget(context.loc.errorHeadingSnackBar,
            context.loc.loadingNFTDataError, 'error'),
      );
    }
  }

  Future<void> launchWallet() async {
    await launchUrlString('wc:', mode: LaunchMode.externalApplication);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      final UserScanResultsScreenArguments navArgs = ModalRoute.of(context)!
          .settings
          .arguments as UserScanResultsScreenArguments;

      if (navArgs.chipIsInitialized) {
        Future<Map<String, dynamic>> meta =
            _fetchMetadata(bytesToUnsignedInt(navArgs.tokenId));
        String imgPath = "";
        _fetchImage(imgPath, meta);
      }
    } catch (e) {
      setState(() {
        imagePath = '';
        loadingImage = true;
      });
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    WalletConnect wc = ref.watch(walletConnectProvider);
    final navArgs = ModalRoute.of(context)!.settings.arguments
        as UserScanResultsScreenArguments;

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
                        wc.connected && connectedWallet == navArgs.nftOwner
                            ?
                            //connected wallet is owner
                            Text(context.loc.congrats,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headline1)
                            : navArgs.chipIsInitialized
                                ? Text(context.loc.authentic,
                                    textAlign: TextAlign.center,
                                    style:
                                        Theme.of(context).textTheme.headline1)
                                :
                                //connected wallet is not owner
                                Text(context.loc.whoops,
                                    textAlign: TextAlign.center,
                                    style:
                                        Theme.of(context).textTheme.headline1),

                        SizedBox(height: 15),

                        //Header Body Text
                        !navArgs.chipIsInitialized
                            ?
                            //chip is not initialized aka NFT does not exist
                            Text(context.loc.nftNotFound,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headline5)
                            : wc.connected &&
                                    connectedWallet == navArgs.nftOwner
                                ?
                                //chip is initialized and wallet is connected
                                Text(context.loc.authenticityNftFound,
                                    textAlign: TextAlign.center,
                                    style:
                                        Theme.of(context).textTheme.headline5)
                                :
                                //chip is initialized and wallet is NOT connected
                                Container()
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
                              !navArgs.chipIsInitialized
                                  ? //chip not initialized aka no NFT exists
                                  SvgPicture.asset(
                                      "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/alert_cross.svg")
                                  : !wc.connected
                                      ?
                                      //chip is initialized and wallet is NOT connected
                                      SvgPicture.asset(
                                          "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/triangle_small.svg")
                                      : connectedWallet == navArgs.nftOwner
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
                          !navArgs.chipIsInitialized
                              ? //chip not initialized aka no NFT exists
                              Text(context.loc.ownershipCouldNotBeVerified,
                                  style: Theme.of(context).textTheme.headline5)
                              : !wc.connected
                                  ?
                                  //chip is initialized and wallet is NOT connected
                                  Text(context.loc.noWalletConnected,
                                      style:
                                          Theme.of(context).textTheme.headline5)
                                  : connectedWallet == navArgs.nftOwner
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
                          !navArgs.chipIsInitialized
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
                                            NFTDetailsScreen.routeName,
                                            arguments:
                                                NFTDetailsScreenArguments(
                                                    navArgs.tokenId,
                                                    navArgs.chipWalletAddress,
                                                    ""));
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
                              tokenId: navArgs.chipIsInitialized
                                  ? bytesToUnsignedInt(navArgs.tokenId)
                                  : null,
                              chipName: 'Infineon Secora',
                              walletAddress: navArgs.chipWalletAddress)
                        ])
                  ]),
              CustomImage(
                width: 130,
                loading: loadingImage,
                imagePath: imagePath,
              ),
            ],
          ),
        ]));
  }
}
