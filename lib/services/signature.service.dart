import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:flutter/foundation.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'dart:io';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:ownerchip_whitelabel/services/web3.services.dart';
import 'package:ownerchip_whitelabel/services/nfc.service.dart';

Future<List> verifySignatureAuthenticity(NFCPlatform nfc, int randomNumber,
    EthereumAddress chipEthereumAddress, chipTokenId) async {
  // get SIGNATURE from NFC chip
  final Uint8List hashedMsg = keccakUtf8(randomNumber.toString());
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

// calculate msg digest (with addded prefix for compliance with personal_sign)
Uint8List prepareMsgForSignature(String hexString) {
  var hashedMsg = keccakUtf8(hexString);

  var prefix = utf8.encode("\x19Ethereum Signed Message:\n32");
  var bytes = BytesBuilder();
  bytes.add(prefix);
  bytes.add(hashedMsg);
  Uint8List prefixedHashedMsg = bytes.toBytes();

  // hash prepended msg
  Uint8List res = keccak256(prefixedHashedMsg);
  return res;
}

// extract & verify signature out of signatureResponse
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

// verify that the tokenId corresponds to the signer
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
