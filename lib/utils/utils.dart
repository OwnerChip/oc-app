import 'package:flutter/foundation.dart';
import 'package:web3dart/crypto.dart';
import 'package:convert/convert.dart';
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

// outputs a Hex string that is always prepended with "0x"
String getEthereumAddressFromUint8List(Iterable list) {
  var concatenate = StringBuffer();
  concatenate.write("0x");
  list.forEach((element) {
    concatenate.write(element.toRadixString(16).padLeft(2, "0"));
  });
  return concatenate.toString();
}

BigInt concatenateUint8List(Uint8List uintList) {
  return BigInt.from(int.parse(uintList.join()));
}

// hex to BigInt - used to calculate tokenId based on EthAddress
BigInt hexToBigInt(Uint8List ethereumAddress) {
  BigInt decimalValue = BigInt.from(0);
  for (int i = 0; i < ethereumAddress.length; i++) {
    decimalValue = decimalValue << 8;
    decimalValue = decimalValue | BigInt.from(ethereumAddress[i]);
  }
  return decimalValue;
}

// BigInt to Bytes
Uint8List bytesFromBigInt(BigInt number) {
  int bytes = (number.bitLength + 7) >> 3;
  var b256 = BigInt.from(256);
  var res = Uint8List(bytes);
  for (int i = 0; i < bytes; i++) {
    res[bytes - 1 - i] = number.remainder(b256).toInt();
    number = number >> 8;
  }
  return res;
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

// wrapper
String getEthereumAddressHexString(Uint8List ethereumAddress) {
  return getEthereumAddressFromUint8List(ethereumAddress);
}

//function to convert Uint8List to hex left padded to 32 bytes
String uint8ListTo32ByteHex(Uint8List uint8List) {
  var hex = bytesToHex(uint8List);
  return hex.padLeft(64, '0');
}

String convertTokenIdToEthereumAddress(BigInt intToConvert) {
  var hex = intToConvert.toRadixString(16);
  return "0x${hex.padLeft(40)}";
}

// specific to secora chip response
Uint8List getPublicKeyFromChipResponse(Uint8List responseGetKeyInfo) {
  return responseGetKeyInfo.sublist(9, 73); //get 64 bit public key
}
