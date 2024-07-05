import 'package:flutter/material.dart';
import 'package:ownerchip_whitelabel/screens/qrCode/QRCodeScannerScreen.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:web3dart/web3dart.dart';

Future<EthereumAddress?> scanWalletQRCode(
  BuildContext context,
) async {
  try {
    final res =
        await Navigator.of(context).pushNamed(QRCodeScannerScreen.routeName);

    if (res == null) {
      return null;
    }

    final split = (res as String).split(":");

    if (split.length == 1) {
      return EthereumAddress.fromHex(res);
    }

    return EthereumAddress.fromHex(split[1]);
  } catch (e, st) {
    Sentry.captureException(e, stackTrace: st);
    talker.error("Error scanning wallet QR code", e, st);
  }

  return null;
}
