import 'package:flutter/material.dart';

class BlueStyle extends ThemeExtension<BlueStyle> {
  const BlueStyle(
      {this.borderColor,
      this.successColor,
      this.warningColor,
      this.errorColor,
      this.progressBarColor,
      this.secondaryShadowColor,
      this.boxDecorationColor});

  final Color? borderColor;
  final Color? successColor;
  final Color? warningColor;
  final Color? errorColor;
  final Color? progressBarColor;
  final Color? secondaryShadowColor;
  final Color? boxDecorationColor;

  @override
  ThemeExtension<BlueStyle> lerp(ThemeExtension<BlueStyle>? other, double t) {
    if (other is! BlueStyle) {
      return this;
    }
    return BlueStyle(
      borderColor: Color.lerp(borderColor, other.borderColor, t),
      successColor: Color.lerp(successColor, other.successColor, t),
      warningColor: Color.lerp(warningColor, other.warningColor, t),
      errorColor: Color.lerp(errorColor, other.errorColor, t),
      progressBarColor: Color.lerp(progressBarColor, other.progressBarColor, t),
      secondaryShadowColor:
          Color.lerp(secondaryShadowColor, other.secondaryShadowColor, t),
      boxDecorationColor:
          Color.lerp(boxDecorationColor, other.boxDecorationColor, t),
    );
  }

  @override
  BlueStyle copyWith({Color? borderColor}) => BlueStyle(
        borderColor: borderColor ?? this.borderColor,
        successColor: warningColor ?? this.successColor,
        warningColor: warningColor ?? this.warningColor,
        errorColor: warningColor ?? this.errorColor,
        progressBarColor: progressBarColor ?? this.progressBarColor,
        secondaryShadowColor: secondaryShadowColor ?? this.secondaryShadowColor,
        boxDecorationColor: boxDecorationColor ?? this.boxDecorationColor,
      );
}
