import 'package:flutter/foundation.dart';
import 'package:web3dart/crypto.dart';
import 'dart:math';

//generates random integer between 0 and 2^32
int makeRandomInt() {
  return Random().nextInt(4294967296);
}

String makeHexFromUint8List(Iterable list) {
  var concatenate = StringBuffer();
  concatenate.write("0x");
  list.forEach((element) {
    concatenate.write(element.toRadixString(16).padLeft(2, '0'));
  });
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

String uint8ListTo32ByteHex(Uint8List uint8List) {
  var hex = '';
  for (var i = 0; i < uint8List.length; i++) {
    hex += uint8List[i].toRadixString(16).padLeft(2, '0');
  }
  return hex.padLeft(64, '0');
}

//int to hex left padded to 32 bytes
String convertTokenIdToEthereumAddress(BigInt intToConvert) {
  var hex = intToConvert.toRadixString(16);
  return "0x${hex.padLeft(40)}";
}

// hex to BigInt
BigInt hexToBigInt(Uint8List ethereumAddress) {
  BigInt decimalValue = BigInt.from(0);
  for (int i = 0; i < ethereumAddress.length; i++) {
    decimalValue = decimalValue << 8;
    decimalValue = decimalValue | BigInt.from(ethereumAddress[i]);
  }
  return decimalValue;
}

Uint8List getEthereumAddressFromPublicKeyResponse(
    Uint8List responseGetKeyInfo) {
  var uin8key = responseGetKeyInfo.sublist(9, 73); //get 64 bit public key
  return publicKeyToAddress(uin8key);
}

BigInt getBigIntFromEthereumAddress(Uint8List ethereumAddress) {
  return hexToBigInt(ethereumAddress);
}

String getEthereumAddressHexString(Uint8List ethereumAddress) {
  return makeHexFromUint8List(ethereumAddress);
}

//extract signature out of signatureResponse
Map<String, Uint8List> extractSignature(Uint8List signatureResponse) {
  String signatureResponseString = String.fromCharCodes(signatureResponse);
  String signature = signatureResponseString.substring(22);

  // int rLength = int.parse(signature.substring(0, 2), radix: 16) * 2;
  // signature = signature.substring(2);
  // String r = signature.substring(0, rLength);

  // signature = signature.substring(2 + rLength);

  // int sLength = int.parse(signature.substring(0, 2), radix: 16) * 2;
  // signature = signature.substring(2);
  // String s = signature.substring(0, sLength);

  //TODO: calculate v
  Map<String, Uint8List> res = {
    "r": signatureResponse,
    "s": signatureResponse,
    "v": signatureResponse
  };
  return res;
}
