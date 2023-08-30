import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';

class PukDisplay extends StatelessWidget {
  PukDisplay({super.key, required this.puk});

  String puk;

  @override
  Widget build(BuildContext context) {
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
              Text('$puk', style: Theme.of(context).textTheme.headlineMedium),
              SizedBox(
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
                  icon: const Icon(Icons.copy))
            ],
          )
        ]);
  }
}
