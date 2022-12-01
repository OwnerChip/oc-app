import 'package:flutter/material.dart';

class BlueStyle extends ThemeExtension<BlueStyle> {
  const BlueStyle(
      {this.borderColor, this.secondaryShadowColor, this.boxDecorationColor});

  final Color? borderColor;
  final Color? secondaryShadowColor;
  final Color? boxDecorationColor;

  @override
  ThemeExtension<BlueStyle> lerp(ThemeExtension<BlueStyle>? other, double t) {
    if (other is! BlueStyle) {
      return this;
    }
    return BlueStyle(
      borderColor: Color.lerp(borderColor, other.borderColor, t),
      secondaryShadowColor:
          Color.lerp(secondaryShadowColor, other.secondaryShadowColor, t),
      boxDecorationColor:
          Color.lerp(boxDecorationColor, other.boxDecorationColor, t),
    );
  }

  @override
  BlueStyle copyWith({Color? borderColor}) => BlueStyle(
        borderColor: borderColor ?? this.borderColor,
        secondaryShadowColor: secondaryShadowColor ?? this.secondaryShadowColor,
        boxDecorationColor: boxDecorationColor ?? this.boxDecorationColor,
      );
}
