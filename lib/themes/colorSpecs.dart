import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

//the environment variable APP_ID as to be passed to the constructor of this class
class CustomColors {
  late Color primaryColor;
  late Color primaryColorLight;
  late Color shadowColor;
  late Color cardColor;
  late Color scaffoldBackgroundColor;
  late Color headline1Color;
  late Color headline2Color;
  late Color headline3Color;
  late Color headline4Color;
  late Color headline5Color;
  late Color headline6Color;
  late Color bodyText1Color;
  late Color bodyText2Color;
  late Color borderColor;
  late Color successColor;
  late Color warningColor;
  late Color errorColor;
  late Color progressBarColor;
  late Color secondaryShadowColor;
  late Color boxDecorationColor;
  late Color black;
  late Color metadataImagePickerIconsColor;
  late Color customRoundedButtonColor;
  late Color customHomeScreenButtonShadowColor;
  late Color chainDropdownTextColor;

  CustomColors(app_environment) {
    switch (app_environment) {
      case 'ownerchip':
        // ownerchip colors
        primaryColor = Color.fromARGB(255, 25, 35, 90);
        primaryColorLight = Color.fromARGB(255, 77, 122, 255);
        shadowColor = Color.fromARGB(70, 0, 0, 77);
        cardColor = Colors.white;
        scaffoldBackgroundColor = Color.fromARGB(255, 240, 241, 246);
        warningColor = Colors.orange;
        headline1Color = primaryColorLight;
        headline2Color = primaryColor;
        headline3Color = primaryColor;
        headline4Color = primaryColor;
        headline5Color = primaryColor;
        headline6Color = primaryColorLight;
        bodyText1Color = primaryColorLight;
        bodyText2Color = primaryColor;
        borderColor = Color.fromARGB(255, 249, 247, 247);
        successColor = Colors.green;
        errorColor = Color(0xFFC72C41);
        progressBarColor = primaryColor;
        secondaryShadowColor = Color.fromARGB(50, 0, 0, 21);
        boxDecorationColor = Color.fromARGB(210, 160, 160, 160);
        black = Colors.black;
        metadataImagePickerIconsColor = Colors.white;
        customRoundedButtonColor = scaffoldBackgroundColor;
        customHomeScreenButtonShadowColor = shadowColor;
        chainDropdownTextColor = Colors.black;

        break;
      case 'ownerchip_infineon':
        // ownerchip colors
        primaryColor = Color.fromARGB(255, 25, 35, 90);
        primaryColorLight = Color.fromARGB(255, 77, 122, 255);
        shadowColor = Color.fromARGB(70, 0, 0, 77);
        cardColor = Colors.white;
        scaffoldBackgroundColor = Color.fromARGB(255, 240, 241, 246);
        warningColor = Colors.orange;
        headline1Color = primaryColorLight;
        headline2Color = primaryColor;
        headline3Color = primaryColor;
        headline4Color = primaryColor;
        headline5Color = primaryColor;
        headline6Color = primaryColorLight;
        bodyText1Color = primaryColorLight;
        bodyText2Color = primaryColor;
        borderColor = Color.fromARGB(255, 249, 247, 247);
        successColor = Colors.green;
        errorColor = Color(0xFFC72C41);
        progressBarColor = primaryColor;
        secondaryShadowColor = Color.fromARGB(50, 0, 0, 21);
        boxDecorationColor = Color.fromARGB(210, 160, 160, 160);
        black = Colors.black;
        metadataImagePickerIconsColor = Colors.white;
        customRoundedButtonColor = scaffoldBackgroundColor;
        customHomeScreenButtonShadowColor = shadowColor;
        chainDropdownTextColor = Colors.black;
        break;
      case 'stebo':
        primaryColor = Color(0xFF00FE93);
        primaryColorLight = Color(0xFF0d8c57);
        shadowColor = Color(0xFF2E2E2E);
        cardColor = Color(0xFF2E2E2E);
        scaffoldBackgroundColor = Color(0xFF1B1B1B);
        warningColor = Colors.orange;
        headline1Color = primaryColor;
        headline2Color = primaryColor;
        headline3Color = primaryColor;
        headline4Color = Color(0xFFFFFFFF);
        headline5Color = Color(0xFFFFFFFF);
        headline6Color = Color(0xFFFFFFFF);
        bodyText1Color = Color(0xFFFFFFFF);
        bodyText2Color = Color(0xFFFFFFFF);
        borderColor = Color(0xFF2E2E2E);
        successColor = Colors.green;
        errorColor = Color(0xFFC72C41);
        progressBarColor = primaryColor;
        secondaryShadowColor = Color(0xFF2E2E2E);
        boxDecorationColor = Color(0xFFFFFFFF);
        black = Colors.black;
        metadataImagePickerIconsColor = scaffoldBackgroundColor;
        customRoundedButtonColor = scaffoldBackgroundColor;
        customHomeScreenButtonShadowColor = shadowColor;
        chainDropdownTextColor = Colors.white;

        break;
      default:
        primaryColor = Color.fromARGB(255, 25, 35, 90);
        primaryColorLight = Color.fromARGB(255, 77, 122, 255);
        shadowColor = Color.fromARGB(70, 0, 0, 77);
        cardColor = Colors.white;
        scaffoldBackgroundColor = Color.fromARGB(255, 240, 241, 246);
        warningColor = Colors.orange;
        headline1Color = primaryColorLight;
        headline2Color = primaryColor;
        headline3Color = primaryColor;
        headline4Color = primaryColor;
        headline5Color = primaryColor;
        headline6Color = primaryColorLight;
        bodyText1Color = primaryColorLight;
        bodyText2Color = primaryColor;
        borderColor = Color.fromARGB(255, 249, 247, 247);
        successColor = Colors.green;
        errorColor = Color(0xFFC72C41);
        progressBarColor = primaryColor;
        secondaryShadowColor = Color.fromARGB(50, 0, 0, 21);
        boxDecorationColor = Color.fromARGB(210, 160, 160, 160);
        black = Colors.black;
        metadataImagePickerIconsColor = Colors.white;
        customRoundedButtonColor = scaffoldBackgroundColor;
        customHomeScreenButtonShadowColor = shadowColor;
        chainDropdownTextColor = Colors.black;

        break;
    }
  }
}
