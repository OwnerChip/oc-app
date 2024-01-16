import 'package:flutter/material.dart';

//misc imports
import 'package:ownerchip_whitelabel/widgets/stylingWidgets/CustomInputDecoration.dart';

class StyledTextInputBox extends StatelessWidget {
  const StyledTextInputBox(
      {super.key,
      required TextEditingController controller,
      required this.setText,
      required this.fillColor,
      this.keyboardType = TextInputType.text,
      this.maxlines = 1,
      this.maxLength,
      this.hintText = ''})
      : _controller = controller;

  final TextEditingController _controller;
  final Function setText;
  final TextInputType keyboardType;
  final int maxlines;
  final int? maxLength;
  final Color fillColor;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      maxLength: maxLength,
      style: Theme.of(context).textTheme.bodyMedium,
      maxLines: maxlines,
      keyboardType: keyboardType,
      controller: _controller,
      decoration:
          customInputDecoration(context, hintText, fillColor: fillColor),
      onChanged: (input) {
        setText(input);
      },
    );
  }
}
