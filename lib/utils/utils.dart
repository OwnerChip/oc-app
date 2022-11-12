import 'package:flutter/foundation.dart';
import 'dart:math';
import 'dart:io';

//check for internet connection
Future<bool> checkInternetConnection() async {
  try {
    final result = await InternetAddress.lookup('example.com');
    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      return true;
    }
    return false;
  } on SocketException catch (_) {
    return false;
  }
}

//generates random integer between 0 and 2^32
int makeRandomInt() {
  return Random().nextInt(4294967296);
}

String makeHexFromUint8List(Iterable list) {
  print("from public key from uint list");
  var concatenate = StringBuffer();
  concatenate.write("0x");
  list.forEach((element) {
    concatenate.write(element.toRadixString(16).padLeft(2, '0'));
  });
  print("public key: ${concatenate.toString()}");
  return concatenate.toString();
}

BigInt concatenateUint8List(Uint8List uintList) {
  return BigInt.from(int.parse(uintList.join()));
}

//function to convert string to hex padded to 32 bytes
String stringToHex(String string) {
  var hex = '';
  for (var i = 0; i < string.length; i++) {
    hex += string.codeUnitAt(i).toRadixString(16);
  }
  //pad length of hex to multiple of 64
  while (hex.length % 64 != 0) {
    hex += '0';
  }
  return hex;
}

//function to convert Uint8List to hex left padded to 32 bytes
String uint8ListTo32ByteHex(Uint8List uint8List) {
  var hex = '';
  for (var i = 0; i < uint8List.length; i++) {
    hex += uint8List[i].toRadixString(16).padLeft(2, '0');
  }
  return hex.padLeft(64, '0');
}

//int to hex left padded to 32 bytes
String intTo32ByteHex(int intToConvert) {
  var hex = intToConvert.toRadixString(16);
  //pad length of hex to multiple of 64
  return hex.padLeft(64, '0');
}
