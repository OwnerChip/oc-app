import 'package:flutter/material.dart';
import '../widgets/CustomSnackBarContent.dart';

SnackBar returnSnackBarWidget(String heading, String text, String alertType) {
  return SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      content: CustomSnackBarContent(
          alertType: alertType, heading: heading, text: text));
}
