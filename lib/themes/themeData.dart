import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/themes/fontSpecs.dart';

class CustomThemeData {
  static ThemeData getThemeData() {
    return ThemeData(
      unselectedWidgetColor: CustomColors(dotenv.get('APP_ID')).primaryColor,
      primaryColor: CustomColors(dotenv.get('APP_ID')).primaryColor,
      primaryColorLight: CustomColors(dotenv.get('APP_ID')).primaryColorLight,
      shadowColor: CustomColors(dotenv.get('APP_ID')).shadowColor,
      scaffoldBackgroundColor:
          CustomColors(dotenv.get('APP_ID')).scaffoldBackgroundColor,
      cardColor: CustomColors(dotenv.get('APP_ID')).cardColor,
      textTheme: TextTheme(
        displayLarge: TextStyle(
            fontSize: CustomFonts(dotenv.get('APP_ID')).headline1FontSize,
            fontWeight: CustomFonts(dotenv.get('APP_ID')).headline1FontWeight,
            color: CustomColors(dotenv.get('APP_ID')).headline1Color,
            fontFamily: CustomFonts(dotenv.get('APP_ID')).headline1Font),
        displayMedium: TextStyle(
            fontSize: CustomFonts(dotenv.get('APP_ID')).headline2FontSize,
            fontFamily: CustomFonts(dotenv.get('APP_ID')).headline2Font,
            fontWeight: CustomFonts(dotenv.get('APP_ID')).headline2FontWeight,
            color: CustomColors(dotenv.get('APP_ID')).headline2Color),
        displaySmall: TextStyle(
            fontSize: CustomFonts(dotenv.get('APP_ID')).headline3FontSize,
            fontFamily: CustomFonts(dotenv.get('APP_ID')).headline3Font,
            fontWeight: CustomFonts(dotenv.get('APP_ID')).headline3FontWeight,
            color: CustomColors(dotenv.get('APP_ID')).headline3Color),
        headlineMedium: TextStyle(
            fontSize: CustomFonts(dotenv.get('APP_ID')).headline4FontSize,
            fontFamily: CustomFonts(dotenv.get('APP_ID')).headline4Font,
            fontWeight: CustomFonts(dotenv.get('APP_ID')).headline4FontWeight,
            color: CustomColors(dotenv.get('APP_ID')).headline4Color),
        headlineSmall: TextStyle(
            fontSize: CustomFonts(dotenv.get('APP_ID')).headline5FontSize,
            fontFamily: CustomFonts(dotenv.get('APP_ID')).headline5Font,
            fontWeight: CustomFonts(dotenv.get('APP_ID')).headline5FontWeight,
            color: CustomColors(dotenv.get('APP_ID')).headline5Color),
        titleLarge: TextStyle(
            fontSize: CustomFonts(dotenv.get('APP_ID')).headline6FontSize,
            fontFamily: CustomFonts(dotenv.get('APP_ID')).headline6Font,
            fontWeight: CustomFonts(dotenv.get('APP_ID')).headline6FontWeight,
            color: CustomColors(dotenv.get('APP_ID')).headline6Color),
        bodyLarge: TextStyle(
            fontSize: CustomFonts(dotenv.get('APP_ID')).bodyText1FontSize,
            fontFamily: CustomFonts(dotenv.get('APP_ID')).bodyText1Font,
            color: CustomColors(dotenv.get('APP_ID')).bodyText1Color,
            fontWeight: CustomFonts(dotenv.get('APP_ID')).bodyText1FontWeight),
        bodyMedium: TextStyle(
            fontSize: CustomFonts(dotenv.get('APP_ID')).bodyText2FontSize,
            fontFamily: CustomFonts(dotenv.get('APP_ID')).bodyText2Font,
            color: CustomColors(dotenv.get('APP_ID')).bodyText2Color,
            fontWeight: CustomFonts(dotenv.get('APP_ID')).bodyText2FontWeight),
        bodySmall: TextStyle(
            fontSize: CustomFonts(dotenv.get('APP_ID')).bodySmallFontSize,
            fontFamily: CustomFonts(dotenv.get('APP_ID')).bodySmallFont,
            color: CustomColors(dotenv.get('APP_ID')).bodySmallColor,
            fontWeight: CustomFonts(dotenv.get('APP_ID')).bodyText2FontWeight),
      ),
    );
  }
}
