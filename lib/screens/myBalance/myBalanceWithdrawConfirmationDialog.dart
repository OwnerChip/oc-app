import 'package:flutter/material.dart';
import 'package:ownerchip_whitelabel/config/chains.dart';
import 'package:ownerchip_whitelabel/domain/myBalance/myBalanceListItem.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomOutlinedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';

class MyBalanceWithdrawConfirmationDialog extends StatelessWidget {
  const MyBalanceWithdrawConfirmationDialog({
    super.key,
    required this.item,
    required this.address,
    required this.amount,
  });

  final MyBalanceListItem item;

  final String address;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.loc.myBalanceConfirmationDialogTitle,
              style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(
              height: 24,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitle(
                        context, context.loc.myBalanceConfirmationRecipient),
                    _buildTitle(
                        context, context.loc.myBalanceConfirmationAmount),
                    _buildTitle(
                        context, context.loc.myBalanceConfirmationCurrency),
                    _buildTitle(
                        context, context.loc.myBalanceConfirmationChain),
                  ],
                ),
                const SizedBox(
                  width: 16,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildValue(
                      context,
                      '${address.substring(0, 7)}...${address.substring(address.length - 4)}',
                    ),
                    _buildValue(context, amount),
                    _buildValue(context, item.name),
                    _buildValue(
                      context,
                      chainConfig[item.network]!.networkName,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(
              height: 24,
            ),
            SizedBox(
              width: double.infinity,
              child: CustomRoundedButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                text: context.loc.myBalanceConfirmationConfirmButton,
              ),
            ),
            const SizedBox(
              height: 12,
            ),
            SizedBox(
              width: double.infinity,
              child: CustomOutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                buttonText: context.loc.myBalanceConfirmationCancelButton,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium!,
    );
  }

  Widget _buildValue(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}
