import 'package:flutter/material.dart';

//the environment variable STYLE_ID as to be passed to the constructor of this class
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

  CustomColors(appEnvironment) {
    switch (appEnvironment) {
      case 'ownerchip':
        // ownerchip colors
        primaryColor = const Color.fromARGB(255, 25, 35, 90);
        primaryColorLight = const Color.fromARGB(255, 77, 122, 255);
        shadowColor = const Color.fromARGB(70, 0, 0, 77);
        cardColor = Colors.white;
        scaffoldBackgroundColor = const Color.fromARGB(255, 240, 241, 246);
        warningColor = Colors.orange;
        headline1Color = primaryColorLight;
        headline2Color = primaryColor;
        headline3Color = primaryColor;
        headline4Color = primaryColor;
        headline5Color = primaryColor;
        headline6Color = primaryColorLight;
        bodyText1Color = primaryColorLight;
        bodyText2Color = primaryColor;
        borderColor = const Color.fromARGB(255, 249, 247, 247);
        successColor = Colors.green;
        errorColor = const Color(0xFFC72C41);
        progressBarColor = primaryColor;
        secondaryShadowColor = const Color.fromARGB(50, 0, 0, 21);
        boxDecorationColor = const Color.fromARGB(210, 160, 160, 160);
        black = Colors.black;
        metadataImagePickerIconsColor = Colors.white;
        customRoundedButtonColor = scaffoldBackgroundColor;
        customHomeScreenButtonShadowColor = shadowColor;
        chainDropdownTextColor = Colors.black;

        break;
      case 'ownerchip_infineon':
        // ownerchip colors
        primaryColor = const Color.fromARGB(255, 25, 35, 90);
        primaryColorLight = const Color.fromARGB(255, 77, 122, 255);
        shadowColor = const Color.fromARGB(70, 0, 0, 77);
        cardColor = Colors.white;
        scaffoldBackgroundColor = const Color.fromARGB(255, 240, 241, 246);
        warningColor = Colors.orange;
        headline1Color = primaryColorLight;
        headline2Color = primaryColor;
        headline3Color = primaryColor;
        headline4Color = primaryColor;
        headline5Color = primaryColor;
        headline6Color = primaryColorLight;
        bodyText1Color = primaryColorLight;
        bodyText2Color = primaryColor;
        borderColor = const Color.fromARGB(255, 249, 247, 247);
        successColor = Colors.green;
        errorColor = const Color(0xFFC72C41);
        progressBarColor = primaryColor;
        secondaryShadowColor = const Color.fromARGB(50, 0, 0, 21);
        boxDecorationColor = const Color.fromARGB(210, 160, 160, 160);
        black = Colors.black;
        metadataImagePickerIconsColor = Colors.white;
        customRoundedButtonColor = scaffoldBackgroundColor;
        customHomeScreenButtonShadowColor = shadowColor;
        chainDropdownTextColor = Colors.black;
        break;
      case 'stebo':
        primaryColor = const Color(0xFF00FE93);
        primaryColorLight = const Color(0xFF0d8c57);
        shadowColor = const Color(0xFF2E2E2E);
        cardColor = const Color(0xFF2E2E2E);
        scaffoldBackgroundColor = const Color(0xFF1B1B1B);
        warningColor = Colors.orange;
        headline1Color = primaryColor;
        headline2Color = primaryColor;
        headline3Color = primaryColor;
        headline4Color = const Color(0xFFFFFFFF);
        headline5Color = const Color(0xFFFFFFFF);
        headline6Color = const Color(0xFFFFFFFF);
        bodyText1Color = const Color(0xFFFFFFFF);
        bodyText2Color = const Color(0xFFFFFFFF);
        borderColor = const Color(0xFF2E2E2E);
        successColor = Colors.green;
        errorColor = const Color(0xFFC72C41);
        progressBarColor = primaryColor;
        secondaryShadowColor = const Color(0xFF2E2E2E);
        boxDecorationColor = const Color(0xFFFFFFFF);
        black = Colors.black;
        metadataImagePickerIconsColor = scaffoldBackgroundColor;
        customRoundedButtonColor = scaffoldBackgroundColor;
        customHomeScreenButtonShadowColor = shadowColor;
        chainDropdownTextColor = Colors.white;

        break;
      default:
        primaryColor = const Color.fromARGB(255, 25, 35, 90);
        primaryColorLight = const Color.fromARGB(255, 77, 122, 255);
        shadowColor = const Color.fromARGB(70, 0, 0, 77);
        cardColor = Colors.white;
        scaffoldBackgroundColor = const Color.fromARGB(255, 240, 241, 246);
        warningColor = Colors.orange;
        headline1Color = primaryColorLight;
        headline2Color = primaryColor;
        headline3Color = primaryColor;
        headline4Color = primaryColor;
        headline5Color = primaryColor;
        headline6Color = primaryColorLight;
        bodyText1Color = primaryColorLight;
        bodyText2Color = primaryColor;
        borderColor = const Color.fromARGB(255, 249, 247, 247);
        successColor = Colors.green;
        errorColor = const Color(0xFFC72C41);
        progressBarColor = primaryColor;
        secondaryShadowColor = const Color.fromARGB(50, 0, 0, 21);
        boxDecorationColor = const Color.fromARGB(210, 160, 160, 160);
        black = Colors.black;
        metadataImagePickerIconsColor = Colors.white;
        customRoundedButtonColor = scaffoldBackgroundColor;
        customHomeScreenButtonShadowColor = shadowColor;
        chainDropdownTextColor = Colors.black;

        break;
    }
  }
}
