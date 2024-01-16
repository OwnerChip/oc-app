import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:control_style/control_style.dart';

//a function that returns a InputDecoration

InputDecoration customInputDecoration(BuildContext context, String hintText,
    {String? labelText, Color? fillColor, Widget? suffix}) {
  Color _fillColor = fillColor ?? CustomColors(dotenv.get('APP_ID')).cardColor;
  String _labelText = labelText ?? '';

  return InputDecoration(
    suffixIcon: suffix,
    suffixIconConstraints: BoxConstraints(maxHeight: double.infinity),
    label: Padding(
        padding: EdgeInsets.only(bottom: 35),
        child: _labelText.isEmpty
            ? Container()
            : Text(
                _labelText,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium!
                    .copyWith(fontWeight: FontWeight.w700),
              )),
    floatingLabelBehavior: FloatingLabelBehavior.always,
    focusColor: Theme.of(context).primaryColorDark,
    hintText: hintText,
    hintStyle: Theme.of(context).textTheme.bodySmall,
    filled: true,
    fillColor: _fillColor,
    border: DecoratedInputBorder(
      child: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(13),
      ),
      shadow: [
        BoxShadow(
          color: CustomColors(dotenv.get('APP_ID')).secondaryShadowColor,
          offset: const Offset(1, 3),
          blurRadius: 3,
        )
      ],
    ),
  );
}
