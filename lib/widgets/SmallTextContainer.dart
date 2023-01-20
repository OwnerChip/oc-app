import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SmallTextContainer extends StatelessWidget {
  const SmallTextContainer({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          Clipboard.setData(ClipboardData(text: text.toString()));
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Copied to clipboard')));
        },
        child: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: CustomColors(dotenv.get('APP_ID')).boxDecorationColor!,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          child: Text(
            '${text.toString().substring(0, 8)}...',
            style: Theme.of(context).textTheme.bodyText1!.copyWith(
                fontSize: 12.0,
                color:
                    CustomColors(dotenv.get('APP_ID')).scaffoldBackgroundColor),
            textAlign: TextAlign.left,
          ),
        ));
  }
}
