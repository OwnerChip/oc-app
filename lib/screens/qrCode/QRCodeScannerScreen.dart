import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';

class QRCodeScannerScreen extends StatefulWidget {
  const QRCodeScannerScreen({super.key});

  static const String routeName = '/qrCodeScannerScreen';

  @override
  State<QRCodeScannerScreen> createState() => _QRCodeScannerScreenState();
}

class _QRCodeScannerScreenState extends State<QRCodeScannerScreen>
    with WidgetsBindingObserver {
  late final MobileScannerController _controller;

  StreamSubscription<Object?>? _subscription;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(autoStart: true);

    _subscription = _controller.barcodes.listen(_handleBarcode);
  }

  @override
  void dispose() {
    _controller.stop();
    _controller.dispose();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: CircularProgressIndicator(
              color: CustomColors(dotenv.get('APP_ID')).primaryColor,
            ),
          ),
          MobileScanner(
            fit: BoxFit.cover,
            errorBuilder: (context, error, child) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Text(
                    'Error: $error',
                  ),
                ),
              );
            },
            controller: _controller,
          ),
          Positioned(
            left: 32,
            top: 64,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // If the controller is not ready, do not try to start or stop it.
    // Permission dialogs can trigger lifecycle changes before the controller is ready.
    if (!_controller.value.isInitialized) {
      return;
    }

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        // Restart the scanner when the app is resumed.
        // Don't forget to resume listening to the barcode events.
        _subscription = _controller.barcodes.listen(_handleBarcode);

        unawaited(_controller.start());
        break;
      case AppLifecycleState.inactive:
        // Stop the scanner when the app is paused.
        // Also stop the barcode events subscription.
        unawaited(_subscription?.cancel());
        _subscription = null;
        unawaited(_controller.stop());
        break;
    }
  }

  void _handleBarcode(BarcodeCapture event) {
    final address = event.barcodes.first.rawValue;
    if (address == null) return;

    _subscription?.cancel();
    _controller.stop();

    Navigator.of(context).pop(address);
  }
}
