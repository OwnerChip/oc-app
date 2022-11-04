import 'package:flutter/foundation.dart';
import 'package:web3dart/crypto.dart';

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

int convertUint8ListToDecimal(Uint8List uintList) {
  int decimalValue = 0;
  for (int i = uintList.length - 1; i >= 0; i--) {
    decimalValue = decimalValue << 8; // shift everything one byte to the left
    decimalValue = decimalValue | uintList[i]; // bitwise or operation
  }
  return decimalValue;
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

// hex to BigInt
BigInt hexToBigInt(String fullString) {
  return BigInt.parse(fullString, radix: 16);
}

Uint8List getEthereumAddressFromPublicKeyResponse(
    Uint8List responseGetKeyInfo) {
  var uin8key = responseGetKeyInfo.sublist(9, 73); //get 64 bit public key
  return publicKeyToAddress(uin8key);
}

BigInt getBigIntFromEthereumAddress(Uint8List ethereumAddress) {
  String i = makeHexFromUint8List(ethereumAddress);
  return hexToBigInt(i);
}

String getEthereumAddressHexString(Uint8List ethereumAddress) {
  return makeHexFromUint8List(ethereumAddress);
}

//extract signature out of signatureResponse
Uint8List extractSignature(pubkey, Uint8List signatureResponse) {
  String signatureResponseString = String.fromCharCodes(signatureResponse);
  String signature = signatureResponseString.substring(22);

  int rLength = int.parse(signature.substring(0, 2), radix: 16) * 2;
  signature = signature.substring(2);
  String r = signature.substring(0, rLength);

  signature = signature.substring(2 + rLength);

  int sLength = int.parse(signature.substring(0, 2), radix: 16) * 2;
  signature = signature.substring(2);
  String s = signature.substring(0, sLength);

  String res = '${hexToInt(r)}${hexToInt(s)}';
  return res;
}
