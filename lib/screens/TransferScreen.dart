//import packages
import 'package:ownerchip_whitelabel/screens/UserScanResultsScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:web3dart/web3dart.dart';
import 'package:async/async.dart';
import 'package:sentry/sentry.dart';

//import services
import 'package:ownerchip_whitelabel/services/providers.service.dart';
import 'package:ownerchip_whitelabel/services/walletconnect.services.dart';
import 'package:ownerchip_whitelabel/services/backend.services.dart';
import 'package:ownerchip_whitelabel/services/web3.services.dart';

//import widgets
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomAppBar.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/returnSnackBarWidget.dart';
import 'package:ownerchip_whitelabel/widgets/layout/CustomOverlay.dart';
import 'package:ownerchip_whitelabel/widgets/ui/SpinningLoadingSvg.dart';
import 'package:ownerchip_whitelabel/widgets/ui/PopUp.dart';

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
  _MoreInfoScreenState createState() => _MoreInfoScreenState();
}

class _MoreInfoScreenState extends ConsumerState<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _inputController = TextEditingController();

  bool isLoading = false;
  bool isRotating = true;
  String loadingSvgPath =
      '${dotenv.get('IMAGE_ASSETS_BASE_URL')}/chip_dark_blue.svg';
  String loadingText = '';

  String textInput = '';

  CancelableOperation? cancellableOperation;

  Future<void> transferToken(Web3App wc, BigInt tokenId, EthereumAddress to,
      SignatureData signatureData, EthereumAddress connectedWallet) async {
    final wcSession = ref.read(wcSessionProvider);
    final TokenInfoObject config =
        await ref.watch(findTokenProvider(tokenId).future);
    final transferProcess = Sentry.startTransaction('initTransfer()', 'task');
    try {
      if (wcSession == null) {
        walletPopupBuilder(context, ref, wc);
      }

      setState(() {
        isLoading = true;
        loadingText = context.loc.transferInProgress;
      });

      sendAnalyticsTrace(
          "$connectedWallet-${tokenId.toString()}", "", "TRANSFER_STARTED");

      final List response = await checkMetaTx(
          config.collectionId, gaslessTransferFunctionSignature);
      final bool canUseGasStation = response[0];
      final metaTxAgreementId = response[1];

      String txnHash;
      if (canUseGasStation) {
        txnHash = await makeAndSendGaslessTx(
            gaslessTransferFunctionSignature,
            config.chainId,
            config.collectionId,
            signatureData,
            connectedWallet,
            wc,
            wcSession!,
            metaTxAgreementId,
            ref.read(walletTypeProvider)!,
            toAccount: to);
      } else {
        txnHash = await makeAndSendNormalTx(
            transferFunctionSignature,
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
        //refresh provider state to update nft owner for next screen
        AsyncValue<EthereumAddress> owner = ref.refresh(nftOwnerProvider);

        //wait for 1 second to show success icon
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          isLoading = false;
        });
        //navigate to user scan result screen
        Navigator.pushNamed(context, UserScanResultsScreen.routeName);
        // send status to analytics
        transferProcess.finish();
        sendAnalyticsTrace("$connectedWallet-${tokenId.toString()}", txnHash,
            "TRANSFER_SUCCESS");
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
      sendAnalyticsTrace(
          "$connectedWallet-${tokenId.toString()}", "", "TRANSFER_ERROR");
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
    final SignatureData signatureData = ref.watch(signatureDataProvider);

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
          appBar: const CustomAppBar(
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
                      const SizedBox(height: 40),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            textAlign: TextAlign.center,
                            context.loc.transferScreenText,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                      ),
                      const SizedBox(height: 60),
                      TextFormField(
                        controller: _inputController,
                        onChanged: (text) => setState(() {
                          textInput = text;
                        }),
                        validator: (value) {
                          if (!validateEthAddress(value)) {
                            return context.loc.pleaseEnterValidWalletAddress;
                          } else {
                            return null;
                          }
                        },
                        decoration: InputDecoration(
                          focusColor: Theme.of(context).primaryColorDark,
                          hintText: context.loc.enterWalletAddress,
                          hintStyle: Theme.of(context).textTheme.bodyMedium,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      CustomRoundedButton(
                          text: context.loc.transferToken,
                          onPressed: (() => {
                                if (_formKey.currentState!.validate())
                                  {
                                    FocusScope.of(context).unfocus(),
                                    fromCancelable(transferToken(
                                        wc!,
                                        chipInfo.tokenId,
                                        EthereumAddress.fromHex(
                                            textInput.trim()),
                                        signatureData,
                                        connectedWallet))
                                  }
                              }))
                    ],
                  ),
                ),
              ]),
        ));
  }
}
