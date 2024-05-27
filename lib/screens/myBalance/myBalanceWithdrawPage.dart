import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/domain/myBalance/myBalanceListItem.dart';
import 'package:ownerchip_whitelabel/services/providers/myBalance/myBalanceNotifier.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/widgets/stylingWidgets/CustomInputDecoration.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomOutlinedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';

class MyBalanceWithdrawPage extends ConsumerStatefulWidget {
  const MyBalanceWithdrawPage({
    super.key,
  });

  @override
  ConsumerState<MyBalanceWithdrawPage> createState() {
    return _MyBalanceWithdrawPageState();
  }
}

class _MyBalanceWithdrawPageState extends ConsumerState<MyBalanceWithdrawPage> {
  final FocusNode _addressFocusNode = FocusNode();
  final TextEditingController _addressController = TextEditingController();

  final FocusNode _amountFocusNode = FocusNode();
  final TextEditingController _amountController = TextEditingController();

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // TODO: add proper validation
  bool _isSendAvailable(MyBalanceListItem item) {
    return item.balance != '0' &&
        _addressController.text.isNotEmpty &&
        _amountController.text.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final myBalanceNotifier = ref.read(myBalanceNotifierProvider);

    final item = myBalanceNotifier.myBalanceListItem;

    if (item == null) {
      return const SizedBox();
    }

    return GestureDetector(
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
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
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
                        style:
                            Theme.of(context).textTheme.displaySmall!.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  // TODO: Convert to EUR
                  Text(
                    "${item.balanceEur} €",
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: CustomOutlinedButton(
                      onPressed: () {
                        _amountController.text = item.balance;
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
                      if (!_isSendAvailable(item)) {
                        return;
                      }

                      // TODO: Implement send
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
    );
  }
}
