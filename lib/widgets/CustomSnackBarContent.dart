import 'package:flutter/material.dart';

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
    return Container(
        padding: const EdgeInsets.all(16.0),
        height: 70,
        decoration: BoxDecoration(
            color: alertType == 'success' ? Colors.green : Color(0xFFC72C41),
            borderRadius: const BorderRadius.all(Radius.circular(20))),
        child: Row(
          children: [
            SizedBox(
                width: 48,
                child: Icon(
                  alertType == 'success' ? Icons.check_circle : Icons.error,
                  size: 36,
                  color: Colors.white,
                )),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(heading,
                        style: TextStyle(fontSize: 18, color: Colors.white)),
                    Text(
                      text,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                  ]),
            )
          ],
        ));
  }
}
