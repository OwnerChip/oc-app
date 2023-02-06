import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/themes/fontSpecs.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomCard.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/LoadingOverlay.dart';
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/localization.helper.dart';
import 'dart:typed_data';

//web3 imports
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web3dart/crypto.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';

// import local files
import '../widgets/ui/CustomAppBar.dart';
import '../utils/navigation.arguments.dart';
import 'HomeScreen.dart';
import '../utils/utils.dart';
import '../services/web3.services.dart';
import '../widgets/ui/returnSnackBarWidget.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/services/providers.service.dart';

class ChipAlreadyInitializedScreen extends ConsumerStatefulWidget {
  const ChipAlreadyInitializedScreen({super.key});

  static const routeName = '/scan-already-initialized';

  @override
  _ChipAlreadyInitializedState createState() => _ChipAlreadyInitializedState();
}

class _ChipAlreadyInitializedState
    extends ConsumerState<ChipAlreadyInitializedScreen> {
  bool isLoading = false;
  bool isRotating = true;
  String loadingSvgPath =
      '${dotenv.get('IMAGE_ASSETS_BASE_URL')}/chip_dark_blue.svg';
  String loadingText = '';

  Future<void> burnToken(
      BigInt tokenId, Uint8List tokenIdHash, MsgSignature signature) async {
    WalletConnect wc = ref.watch(walletConnectProvider);
    TokenInfoObject config = await ref.watch(findTokenProvider(tokenId).future);
    try {
      var burnParams = await makeSignedBurnParams(
          getRPCUrlFromChainId(config.chainId),
          config.collectionId,
          wc.session.accounts[0],
          tokenIdHash,
          signature);

      //if wc bridge is not connected, then reconnect
      if (!wc.bridgeConnected) {
        wc.reconnect();
      }

      await launchUrlString('wc:', mode: LaunchMode.externalApplication);
      var txnHash = await wc.sendCustomRequest(
          method: 'eth_sendTransaction',
          params: burnParams,
          id: makeRandomInt());

      setState(() {
        isLoading = true;
        loadingText = context.loc.burning;
      });

      var txnReceipt =
          await getTxnReceipt(getRPCUrlFromChainId(config.chainId), txnHash);
      if (txnReceipt?.status == true) {
        //this means burn succeeded

        setState(() {
          isRotating = false;
          loadingSvgPath = "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/burn.svg";
          loadingText = context.loc.burnedSuccess;
        });

        //delay 2 second
        await Future.delayed(Duration(seconds: 2));

        // ignore: use_build_context_synchronously
        Navigator.pushReplacementNamed(context, HomeScreen.routeName);
      } else {
        throw Exception(context.loc.burnedError);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        returnSnackBarWidget(
            context.loc.errorHeadingSnackBar, context.loc.burnedError, 'error'),
      );
      print("Error: $e");
    }
  }

  Future<void> burnAndMintToken(Uint8List tokenId) async {}

  @override
  Widget build(BuildContext context) {
    WalletConnect wc = ref.watch(walletConnectProvider);
    final connectedWallet = wc.session.accounts.length > 0
        ? wc.session.accounts[0].toLowerCase()
        : '';
    final navArgs = ModalRoute.of(context)!.settings.arguments
        as ChipAlreadyInitializedScreenArguments;
    final chipInfo = ref.watch(chipInfoProvider);
    final nftOwner = ref.watch(nftOwnerProvider);
    final AsyncValue<Uri> raribleUrl = ref.watch(raribleUrlProvider);
    final AsyncValue<Uri> openseaUrl = ref.watch(openseaUrlProvider);
    final AsyncValue<Uri> blockchainExplorerUrl =
        ref.watch(blockchainExplorerUrlProvider);
    final Uint8List tokenIdHash = keccakUtf8(chipInfo.tokenId.toString());
    final MsgSignature signature = navArgs.signature;

    return LoadingOverlay(
      onPressed: () {
        setState(() {
          isLoading = false;
        });
      },
      isLoading: isLoading,
      loadingText: loadingText,
      rotateIcon: isRotating,
      svgPath: loadingSvgPath,
      child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: CustomAppBar(
            text: context.loc.initializeChip,
            connectedWalletAddress: wc.session.accounts.isEmpty == true
                ? null
                : wc.session.accounts[0].toLowerCase(),
          ),
          body: ScreenBodyLayout(
            withScrollView: false,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomCard(
                  color: CustomColors(dotenv.get('APP_ID')).cardColor,
                  width: 300,
                  children: [
                    //orange round ember warning icon
                    Icon(Icons.warning_amber_rounded,
                        color: CustomColors(dotenv.get('APP_ID')).warningColor,
                        size: CustomFonts(dotenv.get('APP_ID'))
                            .AdminWarningHeadlineFontSize), //spacing
                    const SizedBox(
                      height: 20,
                    ),
                    Text(
                      context.loc.warning,
                      style: TextStyle(
                          color:
                              CustomColors(dotenv.get('APP_ID')).warningColor,
                          fontSize: CustomFonts(dotenv.get('APP_ID'))
                              .AdminWarningSubtextFontSize,
                          fontWeight: CustomFonts(dotenv.get('APP_ID'))
                              .AdminWarningSubtextFontWeight),
                    ),
                    //spacing
                    const SizedBox(height: 10),
                    Text(
                      textAlign: TextAlign.center,
                      context.loc.alreadyLinked,
                      style: Theme.of(context).textTheme.headline5!,
                    ),

                    nftOwner.when(
                        error: (e, s) => Text(context.loc.whoops,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headline1),
                        loading: () => Text(context.loc.loading,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headline1),
                        data: (data) => wc.connected &&
                                connectedWallet == data.toString()
                            ? CustomRoundedButton(
                                width: 250,
                                text: context.loc.burnToken,
                                onPressed: () => {
                                  burnToken(chipInfo.tokenId, navArgs.hashedMsg,
                                      signature)
                                },
                              ) // TODO: display info that admin user is not token owner?
                            : const SizedBox(
                                height: 40,
                              )),
                    const SizedBox(
                      height: 40,
                    ),
                    CustomRoundedButton(
                        width: 250,
                        text: context.loc.showOnExplorer,
                        onPressed: () => {
                              launchUrl(blockchainExplorerUrl.asData!.value,
                                  mode: LaunchMode.externalApplication)
                            }),
                    //spacing
                    const SizedBox(
                      height: 8,
                    ),
                    CustomRoundedButton(
                      width: 250,
                      text: context.loc.showOnOpenSea,
                      onPressed: () => {
                        launchUrl(openseaUrl.asData!.value,
                            mode: LaunchMode.externalApplication)
                      },
                    ),
                    //spacing
                    const SizedBox(
                      height: 8,
                    ),
                    CustomRoundedButton(
                      width: 250,
                      text: context.loc.showOnRarible,
                      onPressed: () => {
                        launchUrl(raribleUrl.asData!.value,
                            mode: LaunchMode.externalApplication)
                      },
                    ),
                    const SizedBox(
                      height: 40,
                    ),
                  ]),
              //spacing
              const SizedBox(
                height: 20,
              ),
              CustomRoundedButton(
                width: 250,
                text: context.loc.cancel,
                onPressed: () => {
                  Navigator.pushReplacementNamed(context, HomeScreen.routeName)
                },
              ),
            ],
          )),
    );
  }
}
