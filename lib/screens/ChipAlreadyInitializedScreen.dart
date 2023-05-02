// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

//import packages
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:async/async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web3dart/web3dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web3dart/crypto.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:sentry/sentry.dart';

//import services
import 'package:ownerchip_whitelabel/services/providers.service.dart';
import 'package:ownerchip_whitelabel/services/backend.services.dart';
import 'package:ownerchip_whitelabel/services/web3.services.dart';
import 'package:ownerchip_whitelabel/services/walletconnect.services.dart';

//import widgets
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';
import 'package:ownerchip_whitelabel/widgets/ui/returnSnackBarWidget.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomCard.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/SpinningLoadingSvg.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomAppBar.dart';
import 'package:ownerchip_whitelabel/widgets/layout/CustomOverlay.dart';

//import screens
import 'package:ownerchip_whitelabel/screens/HomeScreen.dart';

//import utils
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/utils/navigation.arguments.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';

//import misc
import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/themes/fontSpecs.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';

class ChipAlreadyInitializedScreen extends ConsumerStatefulWidget {
  const ChipAlreadyInitializedScreen({super.key});

  static const routeName = '/scan-already-initialized';

  @override
  _ChipAlreadyInitializedState createState() => _ChipAlreadyInitializedState();
}

class _ChipAlreadyInitializedState
    extends ConsumerState<ChipAlreadyInitializedScreen> {
  CancelableOperation? cancellableOperation;

  bool isLoading = false;
  bool isRotating = true;
  String loadingSvgPath =
      '${dotenv.get('IMAGE_ASSETS_BASE_URL')}/chip_dark_blue.svg';
  String loadingText = '';

  Future<void> burnToken(WalletConnect wc, BigInt tokenId,
      SignatureData signatureData, EthereumAddress connectedWallet) async {
    final TokenInfoObject config =
        await ref.watch(findTokenProvider(tokenId).future);
    final BURN_PROCESS = Sentry.startTransaction('initBurn()', 'task');
    try {
      if (!wc.bridgeConnected) {
        wc.reconnect();
      }

      setState(() {
        isLoading = true;
        loadingText = context.loc.burning;
      });

      sendAnalyticsTrace(
          "$connectedWallet-${tokenId.toString()}", "", "BURN_STARTED");

      final List response =
          await checkMetaTx(config.collectionId, gaslessBurnFunctionSignature);
      final bool canUseGasStation = response[0];
      final metaTxAgreementId = response[1];

      //launch metamask
      launchUrlString('wc:', mode: LaunchMode.externalApplication);

      String txnHash;
      if (canUseGasStation) {
        txnHash = await makeAndSendGaslessTx(
            gaslessBurnFunctionSignature,
            config.chainId,
            config.collectionId,
            signatureData,
            connectedWallet,
            wc,
            metaTxAgreementId);
      } else {
        txnHash = await makeAndSendNormalTx(
            burnFunctionSignature,
            config.chainId,
            config.collectionId,
            signatureData,
            connectedWallet,
            wc);
      }

      var txnReceipt =
          await getTxnReceipt(getRPCUrlFromChainId(config.chainId), txnHash);
      if (txnReceipt?.status) {
        //this means burn succeeded
        setState(() {
          isRotating = false;
          loadingSvgPath = "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/burn.svg";
          loadingText = context.loc.burnedSuccess;
        });
        // send status to analytics
        BURN_PROCESS.finish();
        sendAnalyticsTrace(
            "$connectedWallet-${tokenId.toString()}", txnHash, "BURN_SUCCESS");

        await Future.delayed(const Duration(seconds: 2));

        Navigator.pushNamedAndRemoveUntil(
            context, HomeScreen.routeName, (route) => false);
      } else {
        throw Exception(context.loc.burnedError);
      }
    } catch (e, s) {
      setState(() {
        isLoading = false;
      });
      // send Error to analytics
      BURN_PROCESS.throwable = e;
      BURN_PROCESS.status = SpanStatus.aborted();
      BURN_PROCESS.finish();
      sendAnalyticsTrace(
          "$connectedWallet-${tokenId.toString()}", "", "BURN_ERROR");
      await Sentry.captureException(e, stackTrace: s);
      ScaffoldMessenger.of(context).showSnackBar(
        returnSnackBarWidget(
            context.loc.errorHeadingSnackBar, context.loc.burnedError, 'error'),
      );
      print("Error: $e");
    }
  }

  Future<dynamic> fromCancelable(Future<dynamic> future) async {
    cancellableOperation?.cancel();
    cancellableOperation =
        CancelableOperation.fromFuture(future, onCancel: () {});
    return cancellableOperation;
  }

  @override
  Widget build(BuildContext context) {
    final navArgs = ModalRoute.of(context)!.settings.arguments
        as ChipAlreadyInitializedScreenArguments;

    WalletConnect wc = ref.watch(walletConnectProvider);

    final ChipInfoModel chipInfo = ref.watch(chipInfoProvider);
    final AsyncValue<EthereumAddress> nftOwner = ref.watch(nftOwnerProvider);
    final AsyncValue<Uri> raribleUrl = ref.watch(raribleUrlProvider);
    final AsyncValue<Uri> openseaUrl = ref.watch(openseaUrlProvider);
    final AsyncValue<Uri> blockchainExplorerUrl =
        ref.watch(blockchainExplorerUrlProvider);
    final EthereumAddress connectedWallet = wc.session.accounts.isNotEmpty
        ? EthereumAddress.fromHex(wc.session.accounts[0].toLowerCase())
        : zeroAddress;
    Sentry.configureScope(
      (scope) =>
          scope.setUser(SentryUser(id: wc.session.accounts[0].toLowerCase())),
    );
    final MsgSignature signature = navArgs.signature;
    final Uint8List hashedMsg = navArgs.hashedMsg;
    final SignatureData signatureData =
        SignatureData(hashedMsg: hashedMsg, signature: signature);

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
        // enable secondary button
        secondaryButton: true,
        secondaryButtonText: context.loc.troubleshoot,
        secondaryButtonUrl: dotenv.get('SUPPORT_PAGE_URL'),
      ),
      child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: CustomAppBar(
            text: context.loc.initializeChip,
          ),
          body: ScreenBodyLayout(
            withScrollView: false,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomCard(
                  color: CustomColors(dotenv.get('STYLE_ID')).cardColor,
                  width: 300,
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color:
                            CustomColors(dotenv.get('STYLE_ID')).warningColor,
                        size: CustomFonts(dotenv.get('STYLE_ID'))
                            .adminWarningHeadlineFontSize), //spacing
                    const SizedBox(
                      height: 20,
                    ),
                    Text(
                      context.loc.warning,
                      style: TextStyle(
                          color:
                              CustomColors(dotenv.get('STYLE_ID')).warningColor,
                          fontSize: CustomFonts(dotenv.get('STYLE_ID'))
                              .adminWarningSubtextFontSize,
                          fontWeight: CustomFonts(dotenv.get('STYLE_ID'))
                              .adminWarningSubtextFontWeight),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      textAlign: TextAlign.center,
                      context.loc.alreadyLinked,
                      style: Theme.of(context).textTheme.headlineSmall!,
                    ),
                    const SizedBox(
                      height: 40,
                    ),
                    nftOwner.when(
                        error: (e, s) => Container(),
                        loading: () => Text(context.loc.loading,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium),
                        data: (data) => wc.connected && connectedWallet == data
                            ? CustomRoundedButton(
                                width: 250,
                                text: context.loc.burnToken,
                                onPressed: () => {
                                  fromCancelable(burnToken(wc, chipInfo.tokenId,
                                      signatureData, connectedWallet))
                                },
                              )
                            : const SizedBox(
                                height: 40,
                              )),

                    const SizedBox(
                      height: 8,
                    ),
                    CustomRoundedButton(
                        width: 250,
                        text: context.loc.showOnExplorer,
                        onPressed: () => {
                              launchUrl(blockchainExplorerUrl.asData!.value,
                                  mode: LaunchMode.externalApplication)
                            }),
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
                    const SizedBox(
                      height: 8,
                    ),
                    dotenv.get('STYLE_ID') == 'ownerchip_infineon'
                        ? Container()
                        : CustomRoundedButton(
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
