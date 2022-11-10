import 'package:flutter/foundation.dart';
import 'package:convert/convert.dart';
import 'package:web3dart/crypto.dart';
import 'dart:math';
import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/ecc/curves/secp256k1.dart';

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
MsgSignature extractSignature(
    Uint8List publicKey, Uint8List msg, Uint8List signatureResp) {
  print("0x${hex.encode(signatureResp)}");
  String signature = hex.encode(signatureResp);
  print("sigLength ${signature.length}");
  signature = signature.substring(22);
  int rLength = int.parse(signature.substring(0, 2), radix: 16) * 2;
  print("rLength $rLength");
  signature = signature.substring(2);
  String r = signature.substring(0, rLength);

  signature = signature.substring(2 + rLength);
  int sLength = int.parse(signature.substring(0, 2), radix: 16) * 2;
  print("sLength $sLength");
  signature = signature.substring(2);
  String s = signature.substring(0, sLength);

  MsgSignature tmp =
      MsgSignature(BigInt.parse(r, radix: 16), BigInt.parse(s, radix: 16), 0);
  int v = calculateV(publicKey, msg, tmp) ?? 27;
  MsgSignature fin = MsgSignature(tmp.r, tmp.s, v);

  return fin;
}
