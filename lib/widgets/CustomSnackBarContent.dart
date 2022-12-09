import 'package:flutter/material.dart';
import 'package:owner_chip_admin_demo/themes/blueTheme.dart';
import '../themes/customColors.dart';

class CustomSnackBarContent extends StatelessWidget {
  const CustomSnackBarContent(
      {Key? key,
      required this.heading,
      required this.text,
      required this.alertType})
      : super(key: key);

  final String text;
  final String heading;
  final String
      alertType; //alert type can be 'success' or 'error'; different alertTypes can be added and handled in the future

  @override
  Widget build(BuildContext context) {
    final BlueStyle? blueStyle = Theme.of(context).extension<BlueStyle>();

    return Container(
        padding: const EdgeInsets.all(16.0),
        height: 70,
        decoration: BoxDecoration(
            color: alertType == 'success' ? Colors.green : Colors.red,
            borderRadius: const BorderRadius.all(Radius.circular(20))),
        child: Row(
          children: [
            SizedBox(
                width: 48,
                child: Icon(
                    alertType == 'success' ? Icons.check_circle : Icons.error,
                    size: 36,
                    color: Theme.of(context).cardColor)),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(heading,
                        style: TextStyle(
                            fontSize: 18, color: Theme.of(context).cardColor)),
                    Text(
                      text,
                      style: TextStyle(
                          color: Theme.of(context).cardColor, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                  ]),
            )
          ],
        ));
  }
}
