import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/domain/oc/creatorDto.dart';
import 'package:ownerchip_whitelabel/services/backend/backend.services.dart';
import 'package:ownerchip_whitelabel/services/backend/customer/backendCustomerService.dart';
import 'package:ownerchip_whitelabel/services/backend/customer/payload/cardInitPayload.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:web3dart/web3dart.dart';

abstract class BackendCustomer extends Backend {
  static Future<void> sendCardInitToBackend(
    String customerId,
    EthereumAddress chipAddress,
  ) async {
    final service = BackendCustomerService.instanceProd;

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

  static Future<CreatorDto> getCreator(
    EthereumAddress walletAddress,
  ) async {
    final service = BackendCustomerService.instance;

    try {
      talker.info('Getting creator for wallet address: ${walletAddress.hex} - customer id: ${getCustomerId()}');
      return await service
          .getCreator(
        customerId: getCustomerId(),
        walletAddress: walletAddress.hex,
      )
          .catchError((e) {
        Sentry.captureException(
          e,
          stackTrace: StackTrace.current,
        );
        talker.error(
          e,
          StackTrace.current,
        );
        throw Exception('Could not get creator');
      });
    } catch (e, s) {
      Sentry.captureException(
        e,
        stackTrace: s,
      );
      talker.error(e, s);
      rethrow;
    }
  }
}
