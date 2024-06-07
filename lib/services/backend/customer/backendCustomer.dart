import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/services/backend/backend.services.dart';
import 'package:ownerchip_whitelabel/services/backend/customer/backendCustomerService.dart';
import 'package:ownerchip_whitelabel/services/backend/customer/payload/cardInitPayload.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:web3dart/web3dart.dart';

abstract class BackendCustomer extends Backend {
  static Future<void> sendCardInitToBackend(
    String customerId,
    EthereumAddress chipAddress,
  ) async {
    final service = BackendCustomerService.instance;

    try {
      await service.sendCardInitToBackend(
        customerId: customerId,
        appId: dotenv.get('BITRISEIO_PACKAGE_NAME'),
        payload: CardInitPayload(
          id: chipAddress.hex,
        ),
      );
    } catch (e, s) {
      Sentry.captureException(
        e,
        stackTrace: s,
      );
      talker.error(e, s);
    }
  }
}
