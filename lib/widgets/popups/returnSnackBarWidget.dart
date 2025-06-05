import 'package:flutter/material.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomSnackBarContent.dart';



//this function is necessary because ScaffoldMessenger.of(context).showSnackBar() only accepts widget of class SnackBar as an argument; hence its not possible to create sometihng like "CusomtSnackBar" Class and pass it to .showSnackBar() method
SnackBar returnSnackBarWidget(
  String heading,
  String text,
  String alertType, {
  BuildSnackBarAction? actionBuilder,
  Duration duration = const Duration(
    seconds: 5,
  ),
}) {
  return SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: Colors.transparent,
    elevation: 0,
    content: CustomSnackBarContent(
      alertType: alertType,
      heading: heading,
      text: text,
      actionBuilder: actionBuilder,
    ),
    duration: duration,
  );
}
