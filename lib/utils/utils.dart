// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/services/backend.services.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:web3dart/crypto.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:ownerchip_whitelabel/config/chains.dart';
import 'package:cross_file/cross_file.dart';
import 'package:crypto/crypto.dart';
import 'package:web3dart/web3dart.dart';

//validate ethereum address
bool validateEthAddress(String hex) {
  //validate if hex is a valid ethereum address

  bool result = true;

  if (hex == null) {
    return false;
  }

  if (hex.length != 42 || !hex.startsWith('0x')) {
    return false;
  }

  final address = strip0x(hex);
  final hash = bytesToHex(keccakAscii(address.toLowerCase()));
  for (var i = 0; i < 40; i++) {
    // the nth letter should be uppercase if the nth digit of casemap is 1
    final hashedPos = int.parse(hash[i], radix: 16);
    if ((hashedPos > 7 && address[i].toUpperCase() != address[i]) ||
        (hashedPos <= 7 && address[i].toLowerCase() != address[i])) {
      result = false;
    }
  }
  return result;
}

String getNdefUrl() {
  return dotenv.get('IS_INTERNAL') == 'true'
      ? dotenv.get('NDEF_URL_TEST')
      : dotenv.get('NDEF_URL');
}

Future<void> vibrateNTimes(int times) async {
  for (int i = 0; i < times; i++) {
    HapticFeedback.vibrate();
    await Future.delayed(const Duration(milliseconds: 50));
  }
}

Future<void> checkInternetAndHandleUI(BuildContext context) async {
  try {
    //check if there is internet connections
    if (!await checkInternetConnection()) {
      throw Exception("No internet connection");
    }
  } catch (e) {
    //error reading chip
    NfcManager.instance.stopSession();
    ScaffoldMessenger.of(context).showSnackBar(
      returnSnackBarWidget(context.loc.errorHeadingSnackBar,
          context.loc.errorNoInternetConnection, 'error'),
    );
    //delay for 1 second
    await Future.delayed(const Duration(seconds: 1));
    //navigate back to previous screen
    Navigator.pop(context);
  }
}

//check for internet connection
Future<bool> checkInternetConnection() async {
  try {
    final result = await InternetAddress.lookup('google.com');
    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      return true;
    }
    return false;
  } on SocketException catch (_) {
    return false;
  }
}

Future<bool> checkBackendAvailability() async {
  try {
    //get backend client
    final client = getBackendClient();
    await client.get('/auth');
    return true;
  } catch (e) {
    print(e);
    Sentry.captureException(e);
    return false;
  }
}

//check if NFC is activated
Future<bool> checkNfcReader() async {
  try {
    final nfcManager = NfcManager.instance;
    final isAvailable = await nfcManager.isAvailable();
    if (isAvailable) {
      return true;
    }
    return false;
  } catch (e) {
    return false;
  }
}

//generates random integer between 0 and 2^32
int makeRandomInt() {
  return Random().nextInt(4294967296);
}

// hex to BigInt - used to calculate tokenId based on EthAddress
BigInt bytesEthAddrToBigInt(Uint8List ethereumAddress) {
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

//function to convert Uint8List to hex left padded to 32 bytes
String uint8ListTo32ByteHex(Uint8List uint8List) {
  var hex = bytesToHex(uint8List);
  return hex.padLeft(64, '0');
}

String convertTokenIdToEthereumAddress(BigInt intToConvert) {
  var hex = intToConvert.toRadixString(16);
  return "0x${hex.padLeft(40, '0')}";
}

String convertSignatureParamToHexString(BigInt intToConvert) {
  var hex = intToConvert.toRadixString(16);
  return "0x${hex.padLeft(64, '0')}";
}

// specific to secora chip response
Uint8List makePublicKeyFromChipResponse(Uint8List responseGetKeyInfo) {
  return responseGetKeyInfo.sublist(9, 73); //get 64 bit public key
}

//get RPC Url from chain ID from chains.dart
String getRPCUrlFromChainId(int chainId) {
  return chainConfig[chainId]!.rpcUrl;
}

Future<XFile> saveMetadataAsJSONFile(Map<String, dynamic> metadata) async {
  final Directory directory = Directory.systemTemp;
  final File file = File('${directory.path}/metadata.json');
  await file.writeAsString(json.encode(metadata));
  XFile jsonFile = XFile(file.path);
  return jsonFile;
}

//function that returns a file name substring
String getFileNameSubstring(String fileName) {
  //if fileName is short, return full file name
  if (fileName.length <= 14) {
    return fileName;
  }
  //else return substring of file name
  return fileName.substring(0, 5) +
      '...' +
      fileName.substring(fileName.length - 9);
}

String getEthAddressSubstring(EthereumAddress address) {
  return '${address.hex.substring(0, 5)}...';
}

//function that takes file as input and returns sha256 hash as hex string
Future<String> getSha256HashOfFile(File file) async {
  final bytes = await file.readAsBytes();
  final hash = sha256.convert(bytes);
  return hash.toString();
}

Future<XFile> generateVoucherMetadataFile(
    Map<String, dynamic> twinMetadata, BuildContext context) async {
  Map<String, dynamic> voucherMetadata = twinMetadata;
  if (voucherMetadata['description'] == null) {
    voucherMetadata['description'] = '';
  }
  voucherMetadata['description'] +=
      "\n \n${context.loc.voucherNftDescriptionGeneral}, ${context.loc.voucherNftDescriptionAppSpecific}";
  XFile jsonFileVoucher = await saveMetadataAsJSONFile(voucherMetadata);
  return jsonFileVoucher;
}

// generate OwnerCard identifier [from customer 100 to 3582]
String generateOwnerCardIdentifier(int customerId, String baseIdentifier) {
  return (customerId == 103)
      ? '${baseIdentifier}0e0f'
      : (customerId < 256)
          ? '${baseIdentifier}00${customerId.toRadixString(16)}'
          : (customerId < 3583)
              ? '${baseIdentifier}0${customerId.toRadixString(16)}'
              : '';
}

// A function that takes a date string of format "YYYY-MM-DD" and returns a string "DD. MM. YYYY" without leading zeros
String formatDate(String date) {
  // Split the date string by "-" and store the parts in a list
  List<String> parts = date.split("-");
  // Check if the list has exactly 3 elements
  if (parts.length == 3) {
    // Return the formatted string by joining the parts in reverse order with ". "
    return parts.reversed.join(".");
  } else {
    // Return an error message if the input is not valid
    return "Invalid date format";
  }
}
