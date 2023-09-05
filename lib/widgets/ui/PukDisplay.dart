import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/screens/HomeScreen.dart';
import 'package:ownerchip_whitelabel/services/scan.services.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';

class PukDisplay extends ConsumerWidget {
  const PukDisplay({super.key, required this.puk, this.pin});

  final String puk;
  final String? pin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.loc.youCanUseThisPukToResetYourPin,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(puk, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(
                width: 10,
              ),
              IconButton(
                  color: Theme.of(context).primaryColor,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 25,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: puk));
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(context.loc.pukCopied)));
                  },
                  icon: const Icon(Icons.copy)),
            ],
          ),
          const SizedBox(height: 40),
          pin != null
              ? CustomRoundedButton(
                  text: 'Connect OwnerCard',
                  onPressed: (() async {
                    await authenticateCard(ref, context, pin!);

                    Navigator.pushNamedAndRemoveUntil(
                        context, HomeScreen.routeName, (route) => false);
                  }))
              : CustomRoundedButton(
                  text: context.loc.done,
                  onPressed: (() async {
                    Navigator.pushNamedAndRemoveUntil(
                        context, HomeScreen.routeName, (route) => false);
                  }))
        ]);
  }
}
