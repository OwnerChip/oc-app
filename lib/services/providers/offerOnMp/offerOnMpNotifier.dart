import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/domain/oc/creatorDto.dart';
import 'package:ownerchip_whitelabel/services/backend/customer/backendCustomer.dart';
import 'package:ownerchip_whitelabel/services/providers/offerOnMp/offerOnMpData.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';
import 'package:web3dart/web3dart.dart';

class OfferOnMpNotifier extends Notifier<OfferOnMpData> {
  @override
  OfferOnMpData build() {
    return OfferOnMpData.initial();
  }

  Future<void> init() async {
    final session = ref.read(userSessionProvider);
    if (session == null) {
      return;
    }

    EthereumAddress address = session.userWalletAddress;

    if (session.isCertificateCard) {
      final deferredUserSession = ref.read(deferredUserSessionProvider);

      if (deferredUserSession != null &&
          deferredUserSession.userSession?.userWalletAddress != null) {
        address = deferredUserSession.userSession!.userWalletAddress;
      }
    }

    state = state.copyWith(
      loading: true,
      error: false,
    );

    CreatorDto? creator;

    try {
      creator = await BackendCustomer.getCreator(address);
    } catch (e, s) {
      talker.info('Could not get creator');
    }

    state = state.copyWith(
      creatorDto: creator,
      error: false,
      loading: false,
    );
  }
}

final offerOnMpProvider = NotifierProvider<OfferOnMpNotifier, OfferOnMpData>(
  OfferOnMpNotifier.new,
);
