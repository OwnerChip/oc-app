import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/screens/NFTDetailsScreen.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomOutlinedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/appBar/CustomAppBar.dart';

class TokenCreatedScreen extends StatelessWidget {
  const TokenCreatedScreen({super.key});

  static String routeName = '/tokenCreated';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CustomAppBar(
          text: context.loc.tokenCreatedAppBarTitle,
          overrideBackButton: () {
            Navigator.of(context).pushReplacementNamed(
              NFTDetailsScreen.routeName,
            );
          },
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 48.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(
                  flex: 1,
                ),
                Icon(
                  Icons.celebration_outlined,
                  size: 90,
                  color: CustomColors(dotenv.get('APP_ID')).accentColor,
                ),
                const SizedBox(
                  height: 12,
                ),
                Text(
                  context.loc.tokenCreatedTitle,
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(
                  height: 16,
                ),
                Text(
                  context.loc.tokenCreatedSubtitle,
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: 12,
                ),
                SizedBox(
                  width: double.maxFinite,
                  child: CustomOutlinedButton(
                    buttonText: context.loc.tokenCreatedViewTokenButton,
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed(
                        NFTDetailsScreen.routeName,
                      );
                    },
                  ),
                ),
                const Spacer(
                  flex: 4,
                ),
              ],
            ),
          ),
        ));
  }
}
