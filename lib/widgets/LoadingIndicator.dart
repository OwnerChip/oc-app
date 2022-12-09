//CircularProgressIndicator widget that is displayed when loading is true
import 'package:flutter/material.dart';
import 'package:owner_chip_admin_demo/themes/blueTheme.dart';
import '../themes/customColors.dart';

class LoadingIndicator extends StatefulWidget {
  final String loadingText;

  LoadingIndicator({required this.loadingText});

  @override
  _LoadingIndicatorState createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<LoadingIndicator> {
  @override
  Widget build(BuildContext context) {
    final BlueStyle blueStyle = Theme.of(context).extension<BlueStyle>()!;

    return Column(
      children: [
        CircularProgressIndicator(
          color: CustomColors.progressBarColor!,
        ),
        Padding(
          padding: EdgeInsets.all(5),
          child: Text(widget.loadingText),
        )
      ],
    );
  }
}
