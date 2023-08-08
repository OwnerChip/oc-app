import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';

class WalletIcon extends StatelessWidget {
  final String iconPath;
  final String walletName;
  final VoidCallback onTap;

  WalletIcon(this.iconPath, this.walletName, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 243, 243, 243),
                    borderRadius: const BorderRadius.all(Radius.circular(13)),
                    boxShadow: [
                      BoxShadow(
                        color: CustomColors(dotenv.get('APP_ID'))
                            .secondaryShadowColor,
                        offset: const Offset(1, 3),
                        blurRadius: 5,
                      )
                    ]),
                width: 60,
                height: 60,
                child: Padding(
                  padding: const EdgeInsets.all(7),
                  child: Image.asset(iconPath, fit: BoxFit.contain),
                )),
            Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  walletName,
                  style: Theme.of(context)
                      .textTheme
                      .displaySmall!
                      .copyWith(fontSize: 14),
                ))
          ],
        ));
  }
}
