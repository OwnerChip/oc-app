//import packages
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ownerchip_whitelabel/screens/UserScanResultsScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/services/scan.services.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/widgets/popups/CustomOverlay.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:web3dart/web3dart.dart';
import 'package:async/async.dart';
import 'package:sentry/sentry.dart';

//import services
import 'package:ownerchip_whitelabel/services/wallet.services.dart';
import 'package:ownerchip_whitelabel/services/backend.services.dart';
import 'package:ownerchip_whitelabel/services/web3.services.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/services/providers/chipData.dart';
import 'package:ownerchip_whitelabel/services/providers/nftData.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';

//import widgets
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomAppBar.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/SpinningLoadingSvg.dart';

//import misc
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:ownerchip_whitelabel/screens/HomeScreen.dart';

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({Key? key}) : super(key: key);

  static const routeName = '/transfer';

  @override
  _TransferScreenState createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _inputController = TextEditingController();

  bool isLoading = false;
  bool isRotating = true;
  String loadingSvgPath =
      '${dotenv.get('IMAGE_ASSETS_BASE_URL')}/chip_dark_blue.svg';
  String loadingText = '';
  String textInput = '';

  CancelableOperation? cancellableOperation;

  Future<void> toggleLoading() async {
    setState(() {
      isLoading = !isLoading;
    });
  }

  Future<void> approveToken(
      Web3App wc,
      BigInt tokenId,
      EthereumAddress to,
      SignatureData signatureData,
      EthereumAddress connectedWallet,
      String sessionId) async {
    final wcSession = ref.read(wcSessionProvider);
    final TokenInfoObject config =
        await ref.watch(findTokenProvider(tokenId).future);
    final userSession = ref.watch(userSessionProvider);
    final isOwnerCard = userSession?.isOwnerCard;
    final transferProcess = Sentry.startTransaction('initApprove()', 'task');
    try {
      setState(() {
        isLoading = true;
        loadingText = context.loc.transferInProgress;
      });

      sendAnalyticsTrace(sessionId, "", "APPROVE_STARTED", tags: {
        'connectedWallet': connectedWallet.hex,
        'chipWallet':
            convertTokenIdToEthereumAddress(ref.read(chipInfoProvider).tokenId),
        'to': to.toString(),
      });

      final List response =
          await checkMetaTx(config.collectionId, transferFromFunctionSignature);
      final bool canUseGasStation = response[0];
      final metaTxAgreementId = response[1];

      String txnHash;
      if (canUseGasStation) {
        txnHash = await makeAndSendGaslessTx(
            ref,
            context,
            approveFunctionSignature, // APPROVE
            config.chainId,
            config.collectionId,
            signatureData,
            connectedWallet,
            wc,
            wcSession,
            metaTxAgreementId,
            ref.read(walletTypeProvider)!,
            toAccount: to,
            tokenId: tokenId,
            enableRecovery: isOwnerCard,
            toggleLoading: toggleLoading);
      } else {
        txnHash = await makeAndSendNormalTx(
            approveFunctionSignature,
            config.chainId,
            config.collectionId,
            signatureData,
            connectedWallet,
            wc,
            wcSession!,
            ref.read(walletTypeProvider)!,
            toAccount: to);
      }

      var txnReceipt =
          await getTxnReceipt(getRPCUrlFromChainId(config.chainId), txnHash);
      if (txnReceipt?.status) {
        //this means transfer succeeded
        setState(() {
          isRotating = false;
          loadingSvgPath = "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/mint.svg";
          loadingText = context.loc.transferSuccess;
        });
        //refresh provider state to update nft owner & approval for next screen
        await ref.refresh(nftOwnerProvider.future);
        await ref.refresh(nftApprovalProvider.future);

        //wait for 1 second to show success icon
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          isLoading = false;
        });
        //navigate to user scan result screen
        Navigator.pushNamed(context, UserScanResultsScreen.routeName);
        // send status to analytics
        transferProcess.finish();
        sendAnalyticsTrace(sessionId, txnHash, "APPROVE_SUCCESS", tags: {
          'connectedWallet': connectedWallet.hex,
          'chipWallet': convertTokenIdToEthereumAddress(
              ref.read(chipInfoProvider).tokenId),
          'to': to.toString(),
        });
      } else {
        throw Exception(context.loc.transferError);
      }
    } catch (e, s) {
      setState(() {
        isLoading = false;
      });
      // send Error to analytics
      transferProcess.throwable = e;
      transferProcess.status = const SpanStatus.aborted();
      transferProcess.finish();
      sendAnalyticsTrace(sessionId, e.toString(), "APPROVE_ERROR", tags: {
        'connectedWallet': connectedWallet.hex,
        'chipWallet':
            convertTokenIdToEthereumAddress(ref.read(chipInfoProvider).tokenId),
        'to': to.toString(),
      });
      await Sentry.captureException(e, stackTrace: s);
      ScaffoldMessenger.of(context).showSnackBar(
        returnSnackBarWidget(context.loc.errorHeadingSnackBar,
            context.loc.transferError, 'error'),
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
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wc = ref.watch(wcProvider);
    final ChipInfoModel chipInfo = ref.watch(chipInfoProvider);
    final EthereumAddress connectedWallet = ref.watch(userAddressProvider);
    final SignatureData signatureData = ref.watch(chipSignatureDataProvider);
    String sessionId = ref.read(userSessionProvider)!.sessionId;

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
            text: context.loc.transferOwnership,
            showBackButton: true,
          ),
          body: ScreenBodyLayout(
              mainAxisAlignment: MainAxisAlignment.center,
              padding: const EdgeInsets.only(top: 0, bottom: 15),
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      // const SizedBox(height: 40),
                      // SizedBox(
                      //   width: MediaQuery.of(context).size.width * 0.8,
                      //   child: Align(
                      //     alignment: Alignment.center,
                      //     child: Text(
                      //       context.loc.transferOwnership,
                      //       textAlign: TextAlign.center,
                      //       style: Theme.of(context).textTheme.headlineMedium,
                      //     ),
                      //   ),
                      // ),
                      const SizedBox(height: 60),
                      Icon(
                        Icons.credit_card,
                        size: 40,
                        color: CustomColors(dotenv.get('APP_ID')).primaryColor,
                      ),
                      const SizedBox(height: 10),
                      CustomRoundedButton(
                          text: context.loc.transferToOwnerCard,
                          onPressed: (() async {
                            EthereumAddress chipWalletAddress =
                                await getFirstChipQWalletAddress(context, ref);

                            fromCancelable(approveToken(
                                wc!,
                                chipInfo.tokenId,
                                chipWalletAddress,
                                signatureData,
                                connectedWallet,
                                sessionId));
                          })),
                      const SizedBox(height: 30),
                      Text(
                        context.loc.or,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 30),
                      TextFormField(
                        controller: _inputController,
                        onChanged: (text) => setState(() {
                          textInput = text;
                        }),
                        validator: (value) {
                          if (value == null || !validateEthAddress(value)) {
                            return context.loc.pleaseEnterValidWalletAddress;
                          } else {
                            return null;
                          }
                        },
                        cursorColor: Theme.of(context).primaryColorDark,
                        style: Theme.of(context).textTheme.bodyMedium,
                        decoration: InputDecoration(
                          focusColor: Theme.of(context).primaryColorDark,
                          hintText: context.loc.enterWalletAddress,
                          hintStyle: Theme.of(context).textTheme.bodyMedium,
                          filled: true,
                          fillColor:
                              CustomColors(dotenv.get('APP_ID')).cardColor,
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      CustomRoundedButton(
                          text: context.loc.transferToAddress,
                          onPressed: (textInput.isEmpty
                              ? null
                              : () => {
                                    if (_formKey.currentState!.validate())
                                      {
                                        FocusScope.of(context).unfocus(),
                                        fromCancelable(approveToken(
                                            wc!,
                                            chipInfo.tokenId,
                                            EthereumAddress.fromHex(
                                                textInput.trim()),
                                            signatureData,
                                            connectedWallet,
                                            sessionId))
                                      }
                                  })),
                      const SizedBox(
                        height: 20,
                      ),
                      Row(
                        children: [
                          //warning icon
                          const SizedBox(width: 20),
                          SvgPicture.asset(
                              "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/triangle_small.svg"),
                          SizedBox(width: 10),
                          //Text
                          Expanded(
                            child: Text(
                              context.loc.digitalContentWillBeTransferred,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ]),
        ));
  }
}
