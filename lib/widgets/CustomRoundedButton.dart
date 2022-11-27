import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomRoundedButton extends StatelessWidget {
  const CustomRoundedButton(
      {super.key, required this.text, required this.onPressed, this.icon});

  final String text;
  final Function onPressed;
  final Icon? icon; //TODO: Make this SVG to use custom marta icons

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 40,
      child: ElevatedButton(
          onPressed: (() => onPressed()),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(19),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          )),
    );
  }
}
