import 'package:flutter/material.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomOutlinedButton.dart';
import 'package:url_launcher/url_launcher.dart';

import '../animations/PopupLoader.dart';
import 'CustomCard.dart';

class SpinningLoadingSvg extends StatelessWidget {
  const SpinningLoadingSvg({
    Key? key,
    this.onPressed,
    this.loadingText = 'Loading...',
    this.secondaryButtonText = 'Troubleshoot',
    this.secondaryButtonUrl = 'https://www.ownerchip.com/en/support.html',
    required this.svgPath,
    this.opacity = 0.5,
    this.color = Colors.grey,
    this.dismissible = false,
    this.secondaryButton = false,
    this.rotateIcon = true,
  }) : super(key: key);

  final String loadingText;
  final String secondaryButtonText;
  final String secondaryButtonUrl;
  final String svgPath;
  final double opacity;
  final Color color;
  final bool secondaryButton;
  final bool rotateIcon;
  final bool dismissible;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return CustomCard(
        borderColor: Theme.of(context).primaryColor,
        height: secondaryButton ? 400 : 300,
        width: 300,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PopupLoader(
            rotateIcon: rotateIcon,
            svgPath: svgPath,
          ),
          const SizedBox(height: 20),
          Text(
            textAlign: TextAlign.center,
            loadingText,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          onPressed != null
              ? CustomOutlinedButton(
                  buttonText: context.loc.continueInBackground,
                  onPressed: () => onPressed!())
              : Container(),
          // secondary Button
          secondaryButton
              ? Column(children: [
                  const SizedBox(height: 20),
                  CustomOutlinedButton(
                    buttonText: secondaryButtonText,
                    onPressed: () => {
                      launchUrl(Uri.parse(secondaryButtonUrl),
                          mode: LaunchMode.externalApplication)
                    },
                  ),
                ])
              : Container()
        ]);
  }
}
