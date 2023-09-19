import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/screens/HomeScreen.dart';
import 'package:ownerchip_whitelabel/services/scan.services.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';

class SuccessPinSetup extends ConsumerWidget {
  SuccessPinSetup({super.key, required this.pin});

  String pin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wc = ref.watch(wcProvider);

    return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          SizedBox(
            height: 5,
          ),
          Text(
            context.loc.pressConnectToSignIn,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          CustomRoundedButton(
              text: 'Connect OwnerCard',
              onPressed: (() async {
                await authenticateCard(ref, context, pin);

                Navigator.pushNamedAndRemoveUntil(
                    context, HomeScreen.routeName, (route) => false);
              }))
        ]);
  }
}
