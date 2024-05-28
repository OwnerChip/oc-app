import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/config/chains.dart';
import 'package:ownerchip_whitelabel/config/wallets.dart';
import 'package:ownerchip_whitelabel/domain/myBalance/myBalanceListItem.dart';
import 'package:ownerchip_whitelabel/screens/myBalance/myBalanceWithdrawConfirmationDialog.dart';
import 'package:ownerchip_whitelabel/services/providers/blockchainData.dart';
import 'package:ownerchip_whitelabel/services/providers/chipData.dart';
import 'package:ownerchip_whitelabel/services/providers/myBalance/myBalanceNotifier.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/services/wallet.services.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';
import 'package:ownerchip_whitelabel/widgets/popups/CustomOverlay.dart';
import 'package:ownerchip_whitelabel/widgets/stylingWidgets/CustomInputDecoration.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomOutlinedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/SpinningLoadingSvg.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

class MyBalanceWithdrawPage extends ConsumerStatefulWidget {
  const MyBalanceWithdrawPage({
    super.key,
    required this.onBack,
    this.isVisible = false,
  });

  final VoidCallback onBack;
  final bool isVisible;

  @override
  ConsumerState<MyBalanceWithdrawPage> createState() {
    return _MyBalanceWithdrawPageState();
  }
}

class _MyBalanceWithdrawPageState extends ConsumerState<MyBalanceWithdrawPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final FocusNode _addressFocusNode = FocusNode();
  final TextEditingController _addressController = TextEditingController();

  final FocusNode _amountFocusNode = FocusNode();
  final TextEditingController _amountController = TextEditingController();

  double _amount = 0.0;
  bool _processing = false;
  bool _success = false;
  bool _error = false;

  @override
  void didUpdateWidget(covariant MyBalanceWithdrawPage oldWidget) {
    if (widget.isVisible) {
      _amount = 0.0;
      _addressController.clear();
      _amountController.clear();
      _success = false;
      _error = false;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  bool _isSendAvailable(MyBalanceListItem item) {
    return item.balance != BigInt.zero &&
        _addressController.text.isNotEmpty &&
        _amountController.text.isNotEmpty &&
        _amount > 0.0 &&
        _amount <= item.balanceInEther &&
        !_processing;
  }

  @override
  Widget build(BuildContext context) {
    final myBalanceNotifier = ref.watch(myBalanceNotifierProvider);

    final item = myBalanceNotifier.myBalanceListItem;

    if (item == null) {
      return const SizedBox();
    }
    final fiatPrice =
        ref.watch(ethPriceProvider(chainConfig[item.chain]!.nativeTokenSymbol));

    return CustomOverlay(
      show: _processing,
      content: SpinningLoadingSvg(
          onPressed: _success || _error
              ? () {
                  if (mounted) {
                    setState(() {
                      _processing = false;
                    });
                  }

                  _amountController.clear();
                  _addressController.clear();
                  FocusScope.of(context).unfocus();

                  widget.onBack();
                }
              : null,
          buttonText: context.loc.myBalanceWithdrawBackButton,
          secondaryButton: false,
          loadingText: _success
              ? context.loc.myBalanceWithdrawSuccessText
              : _error
                  ? context.loc.myBalanceWithdrawErrorText
                  : context.loc.myBalanceWithdrawLoadingText,
          rotateIcon: !_success && !_error,
          svgPath:
              '${dotenv.get('IMAGE_ASSETS_BASE_URL')}/${_success ? "check.svg" : _error ? "triangle_small.svg" : 'chip_dark_blue.svg'}'),
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: CustomColors(dotenv.get('APP_ID')).secondaryColor,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 32.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const SizedBox(
                    height: 32,
                  ),
                  TextFormField(
                    controller: _addressController,
                    focusNode: _addressFocusNode,
                    decoration: customInputDecoration(
                      context,
                      context.loc.myBalanceReceivingWalletAddress,
                    ),
                    onChanged: (value) {
                      if (mounted) {
                        setState(() {});
                      }
                    },
                  ),
                  const Spacer(
                    flex: 1,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _amountController,
                              focusNode: _amountFocusNode,
                              decoration: customInputDecoration(
                                context,
                                context.loc.myBalanceCryptoAmount,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,18}'),
                                ),
                              ],
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              validator: (value) {
                                try {
                                  if (value != null &&
                                      double.parse(value) >
                                          item.balanceInEther) {
                                    return context
                                        .loc.myBalanceWithdrawSufficientFunds;
                                  }
                                } catch (e) {
                                  return null;
                                }
                                return null;
                              },
                              onChanged: (value) {
                                _amount = double.tryParse(value) ?? 0;

                                if (mounted) {
                                  setState(() {});
                                }
                              },
                            ),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Text(
                            item.name,
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall!
                                .copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      fiatPrice.when(
                        data: (data) {
                          final priceInFiat = data['EUR']!;
                          return Text(
                            "${(_amount * priceInFiat).toStringAsFixed(2)} €",
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(),
                          );
                        },
                        error: (error, st) {
                          return const SizedBox();
                        },
                        loading: () {
                          return SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: CustomColors(
                                dotenv.get('APP_ID'),
                              ).primaryColor,
                              strokeWidth: 1,
                            ),
                          );
                        },
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: CustomOutlinedButton(
                          onPressed: () {
                            int numberOfDecimals = item.balanceInEther
                                .toString()
                                .split('.')
                                .last
                                .length;

                            _amountController.text = item.balanceInEther
                                .toStringAsFixed(max(2, numberOfDecimals));
                            if (mounted) {
                              setState(() {});
                            }
                          },
                          buttonText: context.loc.myBalanceSendMaxButton,
                        ),
                      )
                    ],
                  ),
                  const Spacer(
                    flex: 2,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: _isSendAvailable(item) ? 1.0 : 0.5,
                      child: CustomRoundedButton(
                        onPressed: () async {
                          FocusScope.of(context).unfocus();

                          try {
                            if (!_isSendAvailable(item)) {
                              return;
                            }
                            final walletType = ref.read(walletTypeProvider);

                            if (walletType?.type == EWalletType.web3auth) {
                              final confirmation = await showDialog(
                                context: context,
                                builder: (context) =>
                                    MyBalanceWithdrawConfirmationDialog(
                                  amount: _amountController.text,
                                  address: _addressController.text,
                                  item: item,
                                ),
                              );

                              if (confirmation != true) {
                                return;
                              }
                            }

                            _processing = true;

                            if (mounted) {
                              setState(() {});
                            }

                            final chipSignature =
                                ref.read(chipSignatureDataProvider);
                            final wc = ref.read(wcProvider);
                            final wcSession = ref.read(wcSessionProvider);
                            final userSession = ref.read(userSessionProvider);

                            if (walletType == null ||
                                userSession == null ||
                                wc == null) {
                              _error = true;

                              if (mounted) {
                                setState(() {});
                              }

                              return;
                            }

                            final txHash = await makeAndSendNormalTx(
                              ref,
                              "",
                              item.chain,
                              EthereumAddress.fromHex(_addressController.text),
                              chipSignature,
                              userSession.userWalletAddress,
                              wc,
                              wcSession,
                              walletType,
                              // convert double to BigInt
                              amount: EtherAmount.fromBigInt(
                                EtherUnit.wei,
                                BigInt.parse(
                                    (_amount * 1e18).toStringAsFixed(0)),
                              ),
                              toAccount: EthereumAddress.fromHex(
                                  _addressController.text),
                            );
                            _success = true;
                          } catch (e, st) {
                            _error = true;
                            talker.error(
                                "Error sending transaction: $e", e, st);
                          }

                          if (mounted) {
                            setState(() {});
                          }
                        },
                        text: context.loc.myBalanceSendButton,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 32,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
