import 'package:flutter/material.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'CustomCard.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'PopupLoader.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';

class SpinningLoadingSvg extends StatelessWidget {
  const SpinningLoadingSvg({
    Key? key,
    this.onPressed,
    this.loadingText = 'Loading...',
    required this.svgPath,
    this.opacity = 0.5,
    this.color = Colors.grey,
    this.dismissible = false,
    this.rotateIcon = true,
  }) : super(key: key);

  final String loadingText;
  final String svgPath;
  final double opacity;
  final Color color;
  final bool rotateIcon;
  final bool dismissible;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return CustomCard(
        borderColor: Theme.of(context).primaryColor,
        height: 300,
        width: 300,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PopupLoader(
            rotateIcon: rotateIcon,
            svgPath: svgPath,
          ),
          const SizedBox(height: 20),
          Text(
            loadingText,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          onPressed != null
              ? Column(children: [
                  const SizedBox(height: 20),
                  CustomRoundedButton(
                    text: context.loc.continueInBackground,
                    onPressed: onPressed,
                  )
                ])
              : Container()
        ]);
  }
}
