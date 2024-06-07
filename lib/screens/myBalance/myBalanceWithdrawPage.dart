import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/config/chains.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/config/wallets.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/domain/myBalance/myBalanceListItem.dart';
import 'package:ownerchip_whitelabel/screens/myBalance/myBalanceWithdrawConfirmationDialog.dart';
import 'package:ownerchip_whitelabel/services/backend.services.dart';
import 'package:ownerchip_whitelabel/services/providers/blockchainData.dart';
import 'package:ownerchip_whitelabel/services/providers/chipData.dart';
import 'package:ownerchip_whitelabel/services/providers/myBalance/myBalanceNotifier.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/services/wallet.services.dart';
import 'package:ownerchip_whitelabel/services/web3.services.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';
import 'package:ownerchip_whitelabel/widgets/popups/CustomOverlay.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:ownerchip_whitelabel/widgets/stylingWidgets/CustomInputDecoration.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomOutlinedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/SpinningLoadingSvg.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:web3modal_flutter/services/w3m_service/models/w3m_session.dart';

class MyBalanceWithdrawPage extends ConsumerStatefulWidget {
  const MyBalanceWithdrawPage({
    super.key,
    required this.onBack,
    required this.onProcessing,
    this.isVisible = false,
  });

  final VoidCallback onBack;
  final bool isVisible;

  final bool processing = false;
  final Function(bool processing) onProcessing;

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

  BigInt _amount = BigInt.zero;

  bool _maxAmount = false;

  BigInt? _gasPrice;
  BigInt? _gasAmount;

  @override
  void initState() {
    super.initState();

    // _addressController.text = "0x0593b973a608707287A2b10848921b62bF1Fe97F";
  }

  @override
  void didUpdateWidget(covariant MyBalanceWithdrawPage oldWidget) {
    if (!widget.isVisible) {
      _amount = BigInt.zero;
      _addressController.clear();
      _amountController.clear();
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
        _amount > BigInt.zero &&
        _amount <= item.balance &&
        !widget.processing;
  }

  @override
  Widget build(BuildContext context) {
    final myBalanceNotifier = ref.watch(myBalanceNotifierProvider);
    final item = myBalanceNotifier.myBalanceListItem;

    if (item == null) {
      return const SizedBox();
    }

    final fiatPrice = ref.watch(
      ethPriceProvider(item.symbol),
    );

    return GestureDetector(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: CustomColors(dotenv.get('APP_ID')).secondaryColor,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 24.0,
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
                Row(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          SizedBox(
                            height: 48,
                            child: TextFormField(
                              controller: _addressController,
                              focusNode: _addressFocusNode,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              validator: (value) {
                                if (_addressFocusNode.hasFocus) {
                                  return null;
                                }

                                if (value == null || value.isEmpty) {
                                  return context
                                      .loc.myBalanceWithdrawWrongAddress;
                                }
                                try {
                                  EthereumAddress.fromHex(value);
                                } catch (e) {
                                  return context
                                      .loc.myBalanceWithdrawWrongAddress;
                                }
                                return null;
                              },
                              decoration: customInputDecoration(
                                context,
                                context.loc.myBalanceReceivingWalletAddress,
                              ).copyWith(
                                contentPadding: const EdgeInsets.only(
                                  right: 64,
                                  left: 12,
                                ),
                              ),
                              onChanged: (value) {
                                if (mounted) {
                                  setState(() {});
                                }
                              },
                            ),
                          ),
                          Positioned(
                            right: 12,
                            top: 12,
                            bottom: 0,
                            child: InkWell(
                              onTap: () {
                                Clipboard.getData('text/plain').then((value) {
                                  if (value != null) {
                                    _addressController.text = value.text ?? '';
                                    if (mounted) {
                                      setState(() {});
                                    }
                                  }
                                });
                              },
                              child: Text(context
                                  .loc.myBalanceWithdrawPasteAddressButton),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      context.loc.myBalanceWithdrawMaxAmount(
                          item.balanceInEtherString),
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: SizedBox(
                            height: 48,
                            child: TextFormField(
                              controller: _amountController,
                              focusNode: _amountFocusNode,
                              decoration: customInputDecoration(
                                context,
                                context.loc.myBalanceCryptoAmount,
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                                signed: false,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*([,.]?\d{0,18})?'),
                                ),
                              ],
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              validator: (value) {
                                try {
                                  if (value != null &&
                                      double.parse(value.replaceAll(
                                            ",",
                                            ".",
                                          )) >
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
                                _updateAmount(
                                  item,
                                );
                                _maxAmount = false;

                                if (mounted) {
                                  setState(() {});
                                }
                              },
                            ),
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
                          "${((_amount / BigInt.from(pow(10, item.decimals))).toDouble() * priceInFiat).toStringAsFixed(2)} €",
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
                        onPressed: () async {
                          _maxAmount = true;
                          _estimateGas(
                            item,
                            all: true,
                          ).then((_) {
                            _setMaxAmount(item);
                          });
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
                      onPressed: () {
                        _onSend(item);
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
    );
  }

  Future<void> _onSend(MyBalanceListItem item) async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    try {
      if (!_isSendAvailable(item)) {
        return;
      }
      final walletType = ref.read(walletTypeProvider);

      if (walletType?.type == EWalletType.web3auth) {
        final confirmation =
            await _web3AuthTransactionConfirmation(context, item);

        if (confirmation != true) {
          return;
        }
      }

      widget.onProcessing(true);

      if (mounted) {
        setState(() {});
      }

      _sendAnalytics(
        item,
        description: "Transaction initiated",
        type: "SENDING_TRANSACTION_INITIATED",
      );

      final chipSignature = ref.read(chipSignatureDataProvider);
      final wc = ref.read(wcProvider);
      final wcSession = ref.read(wcSessionProvider);
      final userSession = ref.read(userSessionProvider);

      if (walletType == null || userSession == null || wc == null) {
        _showErrorSnackBar();
        widget.onBack();

        _sendAnalytics(
          item,
          description:
              "Error sending transaction: Wallet type, user session or wc is null",
          type: "SENDING_TRANSACTION_ERROR",
        );

        if (mounted) {
          setState(() {});
        }

        return;
      }

      await _estimateGas(item);

      final String txHash;

      FocusScope.of(context).unfocus();

      if (item.token == null) {
        txHash = await _makeNormalNativeTransaction(
            item: item,
            chipSignature: chipSignature,
            userSession: userSession,
            wc: wc,
            wcSession: wcSession,
            walletType: walletType);
      } else {
        txHash = await _makeTokenTransaction(
          context: context,
          item: item,
          chipSignature: chipSignature,
          userSession: userSession,
          wc: wc,
          wcSession: wcSession,
          walletType: walletType,
        );
      }

      final result = await getTxnReceipt(
        chainConfig[item.chain]!.rpcUrl,
        txHash,
      );

      if (result == null || result.status == false) {
        _showErrorSnackBar();
        widget.onBack();

        _sendAnalytics(
          item,
          description: "Error sending transaction: Transaction not found",
          type: "SENDING_TRANSACTION_ERROR",
        );

        if (mounted) {
          setState(() {});
        }

        return;
      }

      _showSuccessSnackBar();
      widget.onBack();

      _sendAnalytics(item,
          description: "Transaction sent successfully",
          type: "SENDING_TRANSACTION_SUCCESS");
    } catch (e, st) {
      _sendAnalytics(item,
          description: "Error sending transaction: ${e.toString()}",
          type: "SENDING_TRANSACTION_ERROR");

      _showErrorSnackBar();
      widget.onBack();

      talker.error("Error sending transaction: $e", e, st);
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _showSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      returnSnackBarWidget(
        context.loc.successHeadingSnackbar,
        context.loc.myBalanceWithdrawSuccessText,
        "success",
      ),
    );
  }

  void _showErrorSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      returnSnackBarWidget(
        context.loc.errorHeadingSnackBar,
        context.loc.myBalanceWithdrawErrorText,
        "error",
      ),
    );
  }

  void _sendAnalytics(
    MyBalanceListItem item, {
    required String description,
    required String type,
  }) {
    sendAnalyticsTrace(ref.read(userSessionProvider)?.sessionId ?? "unknown",
        description, type,
        tags: {
          "from": ref.read(userSessionProvider)?.userWalletAddress.hex,
          "to": _getReceivingAddress()?.hex,
          "amount": _amount.toString(),
          "balance": item.balance.toString(),
          "chain": item.chain,
          "token": item.token,
        });
  }

  void _updateAmount(MyBalanceListItem item) {
    try {
      _amount = BigInt.from(
        double.parse(_amountController.text.replaceAll(",", ".")) *
            pow(
              10,
              item.decimals,
            ),
      );
      talker.info("Amount: $_amount");
    } catch (e) {
      _amount = BigInt.zero;
    }
  }

  Future<void> _estimateGas(
    MyBalanceListItem item, {
    bool all = false,
  }) async {
    try {
      final receivingAddress = _getReceivingAddress() ?? zeroAddress;
      final userSession = ref.read(userSessionProvider);

      if (item.token == null) {
        _gasPrice = (await estimateGasPrice(chainConfig[item.chain]!.rpcUrl));
        _gasAmount = await estimateGas(
          chainConfig[item.chain]!.rpcUrl,
          receivingAddress,
          Uint8List(0),
          userSession!.userWalletAddress,
          gasPrice: EtherAmount.fromBigInt(EtherUnit.wei, _gasPrice!),
        );
      } else {
        final token = chainTokenConfigs[item.chain]![item.token!];
        final contract = await token.getDeployedContract();
        final data = contract.function('transfer').encodeCall([
          receivingAddress,
          _amount,
        ]);

        _gasAmount = await estimateGas(
          chainConfig[item.chain]!.rpcUrl,
          token.contractAddress,
          data,
          userSession!.userWalletAddress,
        );
      }

      talker.info("GASPRICE: ${_gasPrice}");

      talker.info("GASAMOUNT: ${_gasAmount}");
      // fallback: 300000 gas
      _gasAmount = BigInt.from(max(_gasAmount!.toDouble(), 105000));
      talker.info("GASAMOUNT: ${_gasAmount}");

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      talker.error("Error estimating gas: $e");
    }
  }

  void _setMaxAmount(MyBalanceListItem item) {
    BigInt gasCost = _gasPrice! * _gasAmount! +
        EtherAmount.fromInt(EtherUnit.gwei, 10).getInWei;
    talker.info("Gas cost: $gasCost");
    final maxTransferAmount = item.balance - gasCost;
    talker.info("Max transfer amount: $maxTransferAmount");

    if (_maxAmount) {
      if (maxTransferAmount < BigInt.zero) {
        _amountController.text = "0";
      } else {
        final adjustedAmount =
            maxTransferAmount / BigInt.from(pow(10, item.decimals));
        _amountController.text = adjustedAmount.toStringAsFixed(item.decimals);
      }
      _updateAmount(
        item,
      );
    }
  }

  Future<String> _makeTokenTransaction({
    required BuildContext context,
    required MyBalanceListItem item,
    required SignatureData chipSignature,
    required UserSession userSession,
    required Web3App wc,
    required W3MSession? wcSession,
    required WalletType walletType,
  }) async {
    final blockchainToken = chainTokenConfigs[item.chain]![item.token!];

    final metaTx = await checkMetaTx(
      blockchainToken.contractAddress,
      erc20TransferFunctionSignature,
    );

    if (metaTx[0]) {
      final metaTxAgreementId = metaTx[1];

      final txHash = await makeAndSendGaslessTx(
        ref,
        context,
        erc20TransferFromFunctionSignature,
        item.chain,
        blockchainToken.contractAddress,
        chipSignature,
        userSession.userWalletAddress,
        wc,
        wcSession,
        metaTxAgreementId,
        walletType,
        toggleLoading: () {},
        toAccount: _getReceivingAddress()!,
        amount: _amount,
        token: blockchainToken,
        gasAmount: _gasAmount,
      );

      talker.info("Transaction sent: $txHash");

      return txHash;
    } else {
      // gas station is not available

      final txHash = await makeAndSendNormalTx(
        context,
        ref,
        erc20TransferFunctionSignature,
        item.chain,
        blockchainToken.contractAddress,
        chipSignature,
        userSession.userWalletAddress,
        wc,
        wcSession,
        walletType,
        // convert double to BigInt
        amount: _amount,
        toAccount: _getReceivingAddress()!,
        gasPrice: _gasPrice,
        gasAmount: _gasAmount,
      );

      talker.info("Transaction sent: $txHash");

      return txHash;
    }
  }

  Future<String> _makeNormalNativeTransaction({
    required MyBalanceListItem item,
    required SignatureData chipSignature,
    required UserSession userSession,
    required Web3App wc,
    required W3MSession? wcSession,
    required WalletType walletType,
  }) async {
    return await makeAndSendNormalTx(
      context,
      ref,
      "",
      item.chain,
      _getReceivingAddress()!,
      chipSignature,
      userSession.userWalletAddress,
      wc,
      wcSession,
      walletType,
      // convert double to BigInt
      amount: _amount,
      toAccount: _getReceivingAddress()!,
      gasAmount: _gasAmount,
      gasPrice: _gasPrice,
    );
  }

  EthereumAddress? _getReceivingAddress() {
    try {
      return EthereumAddress.fromHex(
          _addressController.text.trim().toLowerCase());
    } catch (e) {
      return null;
    }
  }

  Future<dynamic> _web3AuthTransactionConfirmation(
      BuildContext context, MyBalanceListItem item) async {
    return await showDialog(
      context: context,
      builder: (context) => MyBalanceWithdrawConfirmationDialog(
        amount: _amountController.text,
        address: _addressController.text,
        item: item,
      ),
    );
  }
}
