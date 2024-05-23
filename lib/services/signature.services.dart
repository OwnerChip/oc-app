import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:flutter/foundation.dart';
import 'package:ownerchip_whitelabel/services/secora.services.dart';
import 'package:ownerchip_whitelabel/services/web3.services.dart';
import 'package:ownerchip_whitelabel/utils/secora.commands.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

/// sign a hash with the private key of the chip
Future<MsgSignature> signHash(
    NFCPlatform nfc,
    int hexKeyNumber,
    EthereumAddress chipEthereumAddress,
    Uint8List hash,
    bool callSelectApp) async {
  if (callSelectApp) await nfc.sendCommand(SELECT_APP);
  final Uint8List getSigCmd = makeSignatureCommand(hexKeyNumber, hash);
  try {
    final List responseGetSignature = await nfc.sendCommand(getSigCmd);
    final Uint8List chipSignatureData = responseGetSignature[0];
    final int responseCode1 = responseGetSignature[1];
    final int responseCode2 = responseGetSignature[2];

    if (responseCode1 == 0x90 && responseCode2 == 0x00) {
      //neccassary for V parameter calculation
      final BigInt signer =
          bytesEthAddrToBigInt(chipEthereumAddress.addressBytes);
      return extractSignature(signer, hash, chipSignatureData);
    } else if (responseCode1 == 0x69 && responseCode2 == 0x85) {
      throw ("Error: Chip is PIN code locked."); //do not change error message, double check if other logic relies on it
    } else {
      throw ("Error: Unable to get chip signature.");
    }
  } catch (e) {
    print(e);
    throw ("ERROR: SIGNATURE FAILED");
  }
}

/// sign a hash with the private key of the chip and verify the signature locally
Future<List> verifySignatureAuthenticity(NFCPlatform nfc, String sessionId,
    EthereumAddress chipEthereumAddress, chipTokenId) async {
  // select app if necessary
  await nfc.sendCommand(SELECT_APP);

  // get SIGNATURE from NFC chip
  final Uint8List hashedMsg = keccakUtf8(sessionId);
  final Uint8List getSigCmd = makeSignatureCommand(0x01, hashedMsg);
  final List responseGetSignature = await nfc.sendCommand(getSigCmd);
  final int responseCode1 = responseGetSignature[1];
  final int responseCode2 = responseGetSignature[2];
  if (responseCode1 == 0x90 && responseCode2 == 0x00) {
    final Uint8List chipSignatureData = responseGetSignature[0];

    final MsgSignature signature =
        extractSignature(chipTokenId, hashedMsg, chipSignatureData);

    // only if true, is the tokenId corresponding to the chip!
    bool verificationResult =
        verifySignature(chipTokenId, hashedMsg, signature.r, signature.s);
    if (!verificationResult) {
      throw ("Error: Verifying chip signature failed.");
    }
    return [hashedMsg, signature];
  } else if (responseCode1 == 0x69 && responseCode2 == 0x85) {
    throw ("Error: Chip is PIN code locked.");
  } else {
    throw ("Error: Please try again.");
  }
}

/// verify the signature of the chip on the smart contract
Future<bool> verifyTokenAuthenticity(
    String chainRpcUrl,
    EthereumAddress collectionId,
    EthereumAddress chipEthereumAddress,
    Uint8List hashedMsg,
    MsgSignature signature) async {
  try {
    await verifyTokenSigner(
        chainRpcUrl, collectionId, chipEthereumAddress, hashedMsg, signature);
    return true;
  } catch (e) {
    print("ERROR: $e");
    throw ("Token signature could not be verified on smart contract");
  }
}

/// calculate msg digest (with added prefix for compliance with personal_sign EIP-191)
// Uint8List prepareMsgForPersonalSignature(String string) {
//   var bytes = BytesBuilder();
//   bytes.add(utf8.encode("\x19Ethereum Signed Message:\n32"));
//   bytes.add(keccakUtf8(hexString));
//   return bytes.toBytes();
// }

Uint8List prepareMsgForPersonalSignature(String message) {
  // Convert the message to hex of utf8 code units
  List<int> utf8CodeUnits = utf8.encode(message);
  String hexUtf8EncodedMessage =
      utf8CodeUnits.map((e) => e.toRadixString(16)).join();

  // get message length
  String messageLength = utf8CodeUnits.length.toString();

  // Prepend the Ethereum prefix and the message length to the message bytes
  String prependedMessage =
      "\x19Ethereum Signed Message:\n" + messageLength + hexUtf8EncodedMessage;

  List<int> fullMessageUtf8 = utf8.encode(prependedMessage);
  String fullmessageHex =
      '0x' + fullMessageUtf8.map((e) => e.toRadixString(16)).join();

  // Hash the prepended message using keccakUtf8
  return keccakUtf8(fullmessageHex);
}

/// extract & verify signature out of signatureResponse
MsgSignature extractSignature(
    BigInt tokenId, Uint8List hashedMsg, Uint8List signatureResp) {
  String signature = hex.encode(signatureResp);

  // jump over counters (2x8), DER tag and length of signature bytes
  signature = signature.substring(22);

  // get r component
  int rLength = int.parse(signature.substring(0, 2), radix: 16) * 2;

  signature = signature.substring(2);
  String rString = signature.substring(0, rLength);
  BigInt r = BigInt.parse(rString, radix: 16);

  // get s component
  signature = signature.substring(2 + rLength);
  int sLength = int.parse(signature.substring(0, 2), radix: 16) * 2;

  signature = signature.substring(2);
  String sString = signature.substring(0, sLength);
  BigInt s = BigInt.parse(sString, radix: 16);

  // check EIP-2 compliance
  var secp256k1N = BigInt.parse(
      "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141",
      radix: 16); // max value on the curve
  var secp256k1halfN =
      BigInt.from(secp256k1N / BigInt.from(2)); // half of the curve
  if (s > secp256k1halfN) {
    s = secp256k1N - s;
  }

  int v = calculateV(tokenId, hashedMsg, r, s);

  return MsgSignature(r, s, v);
}

/// helper function to calculate v parameter for signature
int calculateV(BigInt tokenId, Uint8List hashedMsg, BigInt r, BigInt s) {
  int vResult = 27;
  bool res = false;
  var vValues = [27, 28];
  for (int v in vValues) {
    MsgSignature signature = MsgSignature(r, s, v);
    Uint8List recoveredPubKey = ecRecover(hashedMsg, signature);
    Uint8List recoveredAddress = publicKeyToAddress(recoveredPubKey);
    bool res = bytesEthAddrToBigInt(recoveredAddress) == tokenId;
    if (res) {
      vResult = v;
      break;
    }
  }
  return vResult;
}

/// verify that the tokenId corresponds to the signer
bool verifySignature(BigInt tokenId, Uint8List hashedMsg, BigInt r, BigInt s) {
  bool res = false;
  var vValues = [27, 28];
  for (int v in vValues) {
    MsgSignature signature = MsgSignature(r, s, v);
    Uint8List recoveredPubKey = ecRecover(hashedMsg, signature);
    Uint8List recoveredAddress = publicKeyToAddress(recoveredPubKey);
    res = bytesEthAddrToBigInt(recoveredAddress) == tokenId;
    if (res) {
      print("${bytesEthAddrToBigInt(recoveredAddress)} (recovered tokenId)");
      break;
    }
  }
  return res;
}

/// split signature into signature parameters (r, s, v)
MsgSignature hexSignatureToRSV(String hexSignature) {
  //if signature length is not 132 throw error
  if (hexSignature.length != 132) {
    throw ("ERROR: Signature length is not 132");
  }
  //if signature does not start with 0x throw error
  if (hexSignature.substring(0, 2) != "0x") {
    throw ("ERROR: Signature does not start with 0x");
  }

  //get r, s, v components as Strings
  String rString = hexSignature.substring(2, 66);
  String sString = hexSignature.substring(66, 130);
  String vString = hexSignature.substring(hexSignature.length - 2);

  //convert to BigInt and int
  BigInt r = BigInt.parse(rString, radix: 16);
  BigInt s = BigInt.parse(sString, radix: 16);
  int v = int.parse(vString, radix: 16);

  return MsgSignature(r, s, v);
}

/// convert MsgSignature to json
Map<String, dynamic> msgSignatureToJson(MsgSignature signature) {
  return {
    'r': signature.r.toString(),
    's': signature.s.toString(),
    'v': signature.v,
  };
}

//convert MsgSignature to hex
String msgSignatureToHex(MsgSignature signature) {
  String r = signature.r.toRadixString(16).padLeft(64, '0');
  String s = signature.s.toRadixString(16).padLeft(64, '0');
  String v = signature.v.toRadixString(16);
  return "0x$r$s$v";
}

/// convert json to MsgSignature
MsgSignature msgSignatureFromJson(Map<String, dynamic> json) {
  return MsgSignature(
    BigInt.parse(json['r']),
    BigInt.parse(json['s']),
    json['v'],
  );
}
