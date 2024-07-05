//import packages
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ownerchip_whitelabel/screens/UserScanResultsScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/services/backend/app/backendApp.dart';
import 'package:ownerchip_whitelabel/services/backend/metaTx/backendMetaTx.dart';
import 'package:ownerchip_whitelabel/services/nfc.services.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/globals.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';
import 'package:ownerchip_whitelabel/widgets/popups/CustomOverlay.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:ownerchip_whitelabel/widgets/ui/AddressInputField.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:web3dart/web3dart.dart';
import 'package:async/async.dart';
import 'package:sentry/sentry.dart';

//import services
import 'package:ownerchip_whitelabel/services/wallet.services.dart';
import 'package:ownerchip_whitelabel/services/backend/backend.services.dart';
import 'package:ownerchip_whitelabel/services/web3.services.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/services/providers/chipData.dart';
import 'package:ownerchip_whitelabel/services/providers/nftData.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';

//import widgets
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';
import 'package:ownerchip_whitelabel/widgets/ui/appBar/CustomAppBar.dart';
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
  final FocusNode _focusNode = FocusNode();

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
      Web3App? wc,
      BigInt tokenId,
      EthereumAddress to,
      SignatureData signatureData,
      EthereumAddress connectedWallet,
      String sessionId) async {
    final wcSession = ref.read(wcSessionProvider);
    final TokenChainAndCollection config =
        await ref.watch(findTokenProvider(tokenId).future);
    final UserSession userSession = ref.read(userSessionProvider)!;
    final isOwnerCard = userSession?.isOwnerCard;
    final transferProcess = Sentry.startTransaction('initApprove()', 'task');
    try {
      setState(() {
        isLoading = true;
        loadingText = context.loc.transferInProgress;
      });

      BackendApp.sendAnalyticsTrace(sessionId, "", "APPROVE_STARTED", tags: {
        'connectedWallet': connectedWallet.hex,
        'chipWallet':
            convertTokenIdToEthereumAddress(ref.read(chipInfoProvider).tokenId),
        'to': to.toString(),
      });

      final List response = await BackendMetaTx.checkMetaTx(
          config.collectionId, transferFromFunctionSignature);
      final bool canUseGasStation = response[0];
      final metaTxAgreementId = response[1];

      String txnHash = "";
      Future<void> normalTx() async {
        txnHash = await makeAndSendNormalTx(
            context,
            ref,
            approveFunctionSignature,
            config.chainId,
            config.collectionId,
            signatureData,
            connectedWallet,
            wc!,
            wcSession,
            ref.read(walletTypeProvider)!,
            tokenId: tokenId,
            toAccount: to);
      }

      try {
        if (canUseGasStation) {
          txnHash = await makeAndSendGaslessTx(
              ref,
              ScaffoldKey.getScaffoldKey('TransferScreen').currentContext!,
              approveFunctionSignature,
              // APPROVE
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
          if (wc == null) {
            throw 'Please connect with MetaMask or similar wallet.';
          }

          await normalTx();
        }
      } catch (e, st) {
        Sentry.captureException(e, stackTrace: st);
        talker.error('Error sending gasless transaction', e, st);

        talker.info('Falling back to normal transaction');
        await normalTx();
      }

      talker.info('Transaction hash: $txnHash');

      var txnReceipt =
          await getTxnReceipt(getRPCUrlFromChainId(config.chainId), txnHash);
      if (txnReceipt?.status == true) {
        //this means transfer succeeded
        setState(() {
          isRotating = false;
          loadingSvgPath = "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/mint.svg";
          loadingText = context.loc.transferSuccess;
        });

        try {
          await Future.delayed(const Duration(seconds: 2));
          //refresh provider state to update nft owner & approval for next screen
          await ref.refresh(nftOwnerProvider.future);
          await ref.refresh(nftApprovalProvider.future);
        } catch (e) {
          print(e);
          Sentry.captureException(e);
        }

        setState(() {
          isLoading = false;
        });

        //check if previous route is user scan result screen
        Navigator.pop(navigatorKey.currentContext!);

        // send status to analytics
        transferProcess.finish();
        BackendApp.sendAnalyticsTrace(sessionId, txnHash, "APPROVE_SUCCESS",
            tags: {
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
      BackendApp.sendAnalyticsTrace(sessionId, e.toString(), "APPROVE_ERROR",
          tags: {
            'connectedWallet': connectedWallet.hex,
            'chipWallet': convertTokenIdToEthereumAddress(
                ref.read(chipInfoProvider).tokenId),
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
  void initState() {
    super.initState();

    _inputController.addListener(() {
      setState(() {
        textInput = _inputController.text;
      });
    });

  }
  @override
  void dispose() {
    _inputController.dispose();
    _focusNode.dispose();
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
          // secondaryButton: true,
          // secondaryButtonText: context.loc.troubleshoot,
          // secondaryButtonUrl: dotenv.get('SUPPORT_PAGE_URL'),
        ),
        child: Scaffold(
          key: ScaffoldKey.getScaffoldKey('TransferScreen'),
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
                                await getFirstChipWalletAddressForTransfer(
                                    context, ref);

                            fromCancelable(approveToken(
                                wc,
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
                      AddressInputField(
                        controller: _inputController,
                        focusNode: _focusNode,
                        errorText: context.loc.pleaseEnterValidWalletAddress,
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
                                            wc,
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
