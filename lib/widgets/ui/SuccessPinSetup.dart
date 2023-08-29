import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/screens/HomeScreen.dart';
import 'package:ownerchip_whitelabel/services/providers.services.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/widgets/popups/WalletPopUp.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';

class SuccessPinSetup extends ConsumerWidget {
  SuccessPinSetup({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wc = ref.watch(wcProvider);

    return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),

          //success icon
          Icon(
            Icons.check_circle_outline,
            color: Theme.of(context).primaryColorLight,
            size: 55,
          ),
          SizedBox(
            height: 5,
          ),
          Text(
            'Press connect to sign in with your OwnerCard.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          CustomRoundedButton(
              text: context.loc.connectWallet,
              onPressed: (() => {
                    //pushNameReplacement to HomeScreen
                    Navigator.pushNamedAndRemoveUntil(
                        context, HomeScreen.routeName, (route) => false),
                    walletPopupBuilder(context, ref, wc!)
                  }))
        ]);
  }
}
