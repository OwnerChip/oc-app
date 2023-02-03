import 'package:flutter/material.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'CustomCard.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'PopupLoader.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    Key? key,
    this.onPressed,
    required this.isLoading,
    this.loadingText = 'Loading...',
    required this.svgPath,
    this.opacity = 0.5,
    this.color = Colors.grey,
    this.dismissible = false,
    this.rotateIcon = true,
    required this.child,
  }) : super(key: key);

  final Widget child;
  final bool isLoading;
  final String loadingText;
  final String svgPath;
  final double opacity;
  final Color color;
  final bool rotateIcon;
  final bool dismissible;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: dismissible,
              child: Container(
                color: color.withOpacity(opacity),
                child: Center(
                  child: CustomCard(
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
                          style: Theme.of(context).textTheme.headline4,
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
                      ]),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
