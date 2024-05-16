import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';

class CustomCheckBox extends StatelessWidget {
  const CustomCheckBox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final Function(bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    return Checkbox(
      value: value,
      onChanged: (value) {
        onChanged(
          value ?? false,
        );
      },
      fillColor: MaterialStateProperty.all(
        CustomColors(dotenv.get("APP_ID")).cardColor,
      ),
      checkColor: CustomColors(dotenv.get("APP_ID")).primaryColor,
      side: MaterialStateBorderSide.resolveWith(
        (states) => BorderSide(
          width: 1.0,
          color: CustomColors(dotenv.get("APP_ID")).primaryColor,
          strokeAlign: 1.0,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(2.0),
      ),
    );
  }
}
