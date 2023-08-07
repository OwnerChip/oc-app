import 'dart:convert';
import 'dart:io';
import 'package:convert/convert.dart';
import 'package:flutter/foundation.dart';
import 'package:ownerchip_whitelabel/utils/nfc.commands.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:ownerchip_whitelabel/services/web3.services.dart';
import 'package:ownerchip_whitelabel/services/nfc.services.dart';

/// sign a hash with the private key of the chip
Future<MsgSignature> signHash(NFCPlatform nfc, int hexKeyNumber,
    EthereumAddress chipEthereumAddress, String hash) async {
  await nfc.sendCommand(SELECT_APP);

  final Uint8List hashBytes = hexToBytes(hash);
  final Uint8List getSigCmd = makeSignatureCommand(hexKeyNumber, hashBytes);
  final List responseGetSignature = await nfc.sendCommand(getSigCmd);
  final Uint8List chipSignatureData = responseGetSignature[0];

  //neccassary for V parameter calculation
  final BigInt signer = hexToBigInt(chipEthereumAddress.addressBytes);
  return extractSignature(signer, hashBytes, chipSignatureData);
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
  final Uint8List chipSignatureData = responseGetSignature[0];

  //success would be 0x90, 0x00 for status words
  //final int chipSignatureStatusWord1 = responseGetSignature[1];
  //final int chipSignatureStatusWord2 = responseGetSignature[2];

  final MsgSignature signature =
      extractSignature(chipTokenId, hashedMsg, chipSignatureData);

  // only if true, is the tokenId corresponding to the chip!
  bool verificationResult =
      verifySignature(chipTokenId, hashedMsg, signature.r, signature.s);
  if (!verificationResult) {
    throw ("ERROR: INVALID CHIP! It is not related to tokenId: $chipTokenId");
  }
  return [hashedMsg, signature];
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

/// calculate msg digest (with addded prefix for compliance with personal_sign EIP-191)
Uint8List prepareMsgForSignature(String hexString) {
  var bytes = BytesBuilder();
  bytes.add(utf8.encode("\x19Ethereum Signed Message:\n32"));
  bytes.add(keccakUtf8(hexString));
  return bytes.toBytes();
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
    bool res = hexToBigInt(recoveredAddress) == tokenId;
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
    res = hexToBigInt(recoveredAddress) == tokenId;
    if (res) {
      print("${hexToBigInt(recoveredAddress)} (recovered tokenId)");
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

/// convert json to MsgSignature
MsgSignature msgSignatureFromJson(Map<String, dynamic> json) {
  return MsgSignature(
    BigInt.parse(json['r']),
    BigInt.parse(json['s']),
    json['v'],
  );
}
