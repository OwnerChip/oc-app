import 'package:flutter/material.dart';

class SmallTextContainer extends StatelessWidget {
  const SmallTextContainer({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: const BoxDecoration(
        color: Color.fromARGB(210, 160, 160, 160),
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color:
              Color.fromARGB(255, 255, 255, 255), //TODO: change to theme color
          fontSize: 12,
          fontFamily: 'Roboto', //TODO: change to theme font
          fontWeight: FontWeight.w400,
        ),
        textAlign: TextAlign.left,
      ),
    );
  }
}
