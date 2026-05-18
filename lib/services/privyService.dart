import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';
import 'package:privy_flutter/privy_flutter.dart';

late Privy privyInstance;

bool _privyInitialized = false;

Future<void> initPrivy() async {
  if (_privyInitialized) return;

  final config = PrivyConfig(
    appId: dotenv.get('PRIVY_APP_ID'),
    appClientId: dotenv.get('PRIVY_CLIENT_ID'),
    logLevel: PrivyLogLevel.none,
  );

  privyInstance = Privy.init(config: config);

  _privyInitialized = true;
}


