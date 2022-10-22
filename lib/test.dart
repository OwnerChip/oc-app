//function that converts uint8list to decimal number
import 'package:flutter/foundation.dart';

int convertUint8ListToDecimal(Uint8List uintList) {
  int decimalValue = 0;
  for (int i = 0; i < uintList.length; i++) {
    decimalValue = decimalValue << 8; // shift everything one byte to the left
    decimalValue = decimalValue | uintList[i]; // bitwise or operation
  }
  return decimalValue;
}
