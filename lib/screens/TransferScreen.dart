//import packages
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/screens/HomeScreen.dart';
import 'package:ownerchip_whitelabel/screens/nftActionsScreenMixin.dart';
import 'package:ownerchip_whitelabel/services/nfc.services.dart';
import 'package:ownerchip_whitelabel/services/providers/chipData.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/globals.dart';
//import misc
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
//import widgets
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';
import 'package:ownerchip_whitelabel/widgets/popups/CustomOverlay.dart';
import 'package:ownerchip_whitelabel/widgets/ui/AddressInputField.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/SpinningLoadingSvg.dart';
import 'package:ownerchip_whitelabel/widgets/ui/appBar/CustomAppBar.dart';
import 'package:web3dart/web3dart.dart';

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({
    Key? key,
  }) : super(key: key);

  static const routeName = '/transfer';

  @override
  _TransferScreenState createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen>
    with NftActionScreenMixin<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  String textInput = '';

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
    final wc = ref.watch(w3mServiceProvider);
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
                              sessionId,
                            ));
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
                                          sessionId,
                                        ))
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
