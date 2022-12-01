import 'package:flutter/material.dart';
import 'package:owner_chip_admin_demo/themes/BlueTheme.dart';
import 'package:flutter/services.dart';

class SmallTextContainer extends StatelessWidget {
  const SmallTextContainer({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final BlueStyle blueStyle = Theme.of(context).extension<BlueStyle>()!;

    return GestureDetector(
        onTap: () {
          Clipboard.setData(ClipboardData(text: text.toString()));
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Copied to clipboard')));
        },
        child: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: blueStyle.boxDecorationColor,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: Theme.of(context).scaffoldBackgroundColor,
              fontSize: 12,
              fontFamily: 'Roboto', //TODO: change to theme font
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.left,
          ),
        ));
  }
}
