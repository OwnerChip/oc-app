import 'dart:ui';
import 'package:flutter/material.dart';

// font constants (feel free to change these settings as neccessary!)
const primaryFont = 'Ubuntu';
const secondaryFont = 'Poppins';
const headerFont = 'RobotoSlab';

class CustomFonts {
  // font weight constants (feel free to change these settings as neccessary!)
  late FontWeight headline1FontWeight;
  late String headline1Font = headerFont;
  late double headline1FontSize;

  late FontWeight headline2FontWeight;
  late String headline2Font = headerFont;
  late double headline2FontSize;

  // CustomAppBar
  late FontWeight headline3FontWeight;
  late String headline3Font = headerFont;
  late double headline3FontSize;

  late FontWeight headline4FontWeight;
  late String headline4Font = headerFont;
  late double headline4FontSize;

  late FontWeight headline5FontWeight;
  late String headline5Font = headerFont;
  late double headline5FontSize;

  late FontWeight headline6FontWeight;
  late String headline6Font = headerFont;
  late double headline6FontSize;

  late FontWeight bodyText1FontWeight;
  late String bodyText1Font = primaryFont;
  late double bodyText1FontSize;

  late FontWeight bodyText2FontWeight;
  late String bodyText2Font = primaryFont;
  late double bodyText2FontSize;

  late double AdminWarningHeadlineFontSize;
  late FontWeight AdminWarningSubtextFontWeight;
  late double AdminWarningSubtextFontSize;

  late FontWeight MetadataNameFontWeight;
  late double MetadataNameFontSize;

  late FontWeight MetadataDescriptionFontWeight;
  late double MetadataDescriptionFontSize;

  CustomFonts(app_environment) {
    switch (app_environment) {
      case 'ownerchip':
        headline1FontWeight = FontWeight.bold;
        headline1Font = headerFont;
        headline1FontSize = 32.0;

        headline2FontWeight = FontWeight.bold;
        headline2Font = headerFont;
        headline2FontSize = 32.0;

        // CustomAppBar
        headline3FontWeight = FontWeight.w500;
        headline3Font = headerFont;
        headline3FontSize = 20.0;

        headline4FontWeight = FontWeight.w600;
        headline4Font = headerFont;
        headline4FontSize = 20.0;

        headline5FontWeight = FontWeight.bold;
        headline5Font = headerFont;
        headline5FontSize = 16.0;

        headline6FontWeight = FontWeight.bold;
        headline6Font = headerFont;
        headline6FontSize = 15.0;

        bodyText1FontWeight = FontWeight.normal;
        bodyText1Font = primaryFont;
        bodyText1FontSize = 16.0;

        bodyText2FontWeight = FontWeight.normal;
        bodyText2Font = primaryFont;
        bodyText2FontSize = 16.0;

        AdminWarningHeadlineFontSize = 80.0;
        AdminWarningSubtextFontWeight = FontWeight.bold;
        AdminWarningSubtextFontSize = 28.0;

        MetadataNameFontWeight = FontWeight.bold;
        MetadataNameFontSize = 20.0;

        MetadataDescriptionFontWeight = FontWeight.normal;
        MetadataDescriptionFontSize = 14.0;
        break;
      case 'stebo':
        headline1FontWeight = FontWeight.bold;
        headline1Font = headerFont;
        headline1FontSize = 32.0;

        headline2FontWeight = FontWeight.bold;
        headline2Font = headerFont;
        headline2FontSize = 32.0;

        // CustomAppBar
        headline3FontWeight = FontWeight.w500;
        headline3Font = headerFont;
        headline3FontSize = 20.0;

        headline4FontWeight = FontWeight.w600;
        headline4Font = headerFont;
        headline4FontSize = 20.0;

        headline5FontWeight = FontWeight.bold;
        headline5Font = headerFont;
        headline5FontSize = 16.0;

        headline6FontWeight = FontWeight.bold;
        headline6Font = headerFont;
        headline6FontSize = 15.0;

        bodyText1FontWeight = FontWeight.normal;
        bodyText1Font = primaryFont;
        bodyText1FontSize = 16.0;

        bodyText2FontWeight = FontWeight.normal;
        bodyText2Font = primaryFont;
        bodyText2FontSize = 16.0;

        AdminWarningHeadlineFontSize = 80.0;
        AdminWarningSubtextFontWeight = FontWeight.bold;
        AdminWarningSubtextFontSize = 28.0;

        MetadataNameFontWeight = FontWeight.bold;
        MetadataNameFontSize = 20.0;

        MetadataDescriptionFontWeight = FontWeight.normal;
        MetadataDescriptionFontSize = 14.0;
        break;
      default:
        headline1FontWeight = FontWeight.bold;
        headline1Font = headerFont;
        headline1FontSize = 32.0;

        headline2FontWeight = FontWeight.bold;
        headline2Font = headerFont;
        headline2FontSize = 32.0;

        // CustomAppBar
        headline3FontWeight = FontWeight.w500;
        headline3Font = headerFont;
        headline3FontSize = 20.0;

        headline4FontWeight = FontWeight.w600;
        headline4Font = headerFont;
        headline4FontSize = 20.0;

        headline5FontWeight = FontWeight.bold;
        headline5Font = headerFont;
        headline5FontSize = 16.0;

        headline6FontWeight = FontWeight.bold;
        headline6Font = headerFont;
        headline6FontSize = 15.0;

        bodyText1FontWeight = FontWeight.normal;
        bodyText1Font = primaryFont;
        bodyText1FontSize = 16.0;

        bodyText2FontWeight = FontWeight.normal;
        bodyText2Font = primaryFont;
        bodyText2FontSize = 16.0;

        AdminWarningHeadlineFontSize = 80.0;
        AdminWarningSubtextFontWeight = FontWeight.bold;
        AdminWarningSubtextFontSize = 28.0;

        MetadataNameFontWeight = FontWeight.bold;
        MetadataNameFontSize = 20.0;

        MetadataDescriptionFontWeight = FontWeight.normal;
        MetadataDescriptionFontSize = 14.0;
        break;
    }
  }
}
