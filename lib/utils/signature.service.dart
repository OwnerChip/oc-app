import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:convert/convert.dart';
import 'package:web3dart/crypto.dart';
import 'dart:math';
import 'dart:io';
import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/ecc/curves/secp256k1.dart';

Uint8List prepareMsgForSignature(String hexString) {
  // similar to ethers.utils.keccak256(ethers.utils.toUtf8Bytes(msg)))
  var hashedMsg = keccak256(Uint8List.fromList(utf8.encode(hexString)));

  // add prefix for compliance with personal_sign
  var prefix = utf8.encode("\x19Ethereum Signed Message:\n32");
  var bytes = BytesBuilder();
  bytes.add(prefix);
  bytes.add(hashedMsg);
  Uint8List prefixedHashedMsg = bytes.toBytes();

  // hash prepended msg
  Uint8List res = keccak256(prefixedHashedMsg);
  print("32byte msg hash: ${hex.encode(res)}");
  return res;
}

// internal function copied from web3dart lib
ECPoint _decompressKey(BigInt xBN, bool yBit, ECCurve c) {
  List<int> x9IntegerToBytes(BigInt s, int qLength) {
    final bytes = intToBytes(s);

    if (qLength < bytes.length) {
      return bytes.sublist(0, bytes.length - qLength);
    } else if (qLength > bytes.length) {
      final tmp = List<int>.filled(qLength, 0);

      final offset = qLength - bytes.length;
      for (var i = 0; i < bytes.length; i++) {
        tmp[i + offset] = bytes[i];
      }

      return tmp;
    }

    return bytes;
  }

  final compEnc = x9IntegerToBytes(xBN, 1 + ((c.fieldSize + 7) ~/ 8));
  compEnc[0] = yBit ? 0x03 : 0x02;
  return c.decodePoint(compEnc)!;
}

// function trying to guess V signature param
int? calculateV(
    Uint8List publicKey, Uint8List msg, MsgSignature signatureData) {
  final ECSignature sig = ECSignature(signatureData.r, signatureData.s);
  final ECDomainParameters params = ECCurve_secp256k1();
  var recId = -1;

  for (var i = 0; i < 4; i++) {
    final n = params.n;
    final i = BigInt.from(recId ~/ 2);
    final x = sig.r + (i * n);

    //Parameter q of curve
    final prime = BigInt.parse(
      'fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f',
      radix: 16,
    );
    if (x.compareTo(prime) >= 0) return null;

    final R = _decompressKey(x, (recId & 1) == 1, params.curve);
    if (!(R * n)!.isInfinity) return null;

    final e = bytesToUnsignedInt(msg);

    final eInv = (BigInt.zero - e) % n;
    final rInv = sig.r.modInverse(n);
    final srInv = (rInv * sig.s) % n;
    final eInvrInv = (rInv * eInv) % n;

    final q = (params.G * eInvrInv)! + (R * srInv);

    final bytes = q!.getEncoded(false);
    BigInt k = bytesToUnsignedInt(bytes.sublist(1));

    if (k == bytesToUnsignedInt(publicKey)) {
      recId = i.toInt();
      break;
    }
  }
  if (recId == -1) {
    throw Exception(
      'Could not construct a recoverable key. This should never happen',
    );
  }

  return recId + 27;
}

//extract signature out of signatureResponse
MsgSignature extractSignature(Uint8List signatureResp) {
  String signature = hex.encode(signatureResp);

  // jump over counters (2x8), DER tag and length of signature bytes
  signature = signature.substring(22);

  // get r component
  int rLength = int.parse(signature.substring(0, 2), radix: 16) * 2;
  print("r length $rLength");

  signature = signature.substring(2);
  String r = "${signature.substring(0, rLength)}";
  print("r: $r");

  // get s component
  signature = signature.substring(2 + rLength);
  int sLength = int.parse(signature.substring(0, 2), radix: 16) * 2;
  print("s length $sLength");

  signature = signature.substring(2);
  String s = "${signature.substring(0, sLength)}";
  print("s: $s");

  // calculate v component
  int v = 28;

  return MsgSignature(
      BigInt.parse(r, radix: 16), BigInt.parse(s, radix: 16), v);
}
