import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:reown_appkit/reown_appkit.dart';

//****WALLETCONNECT****

class _W3mServiceNotifier extends Notifier<ReownAppKitModal?> {
  @override
  ReownAppKitModal? build() {
    ref.keepAlive();
    return null;
  }
}

final w3mServiceProvider =
    NotifierProvider<_W3mServiceNotifier, ReownAppKitModal?>(
        _W3mServiceNotifier.new);

class _WalletTypeNotifier extends Notifier<WalletType?> {
  @override
  WalletType? build() {
    ref.keepAlive();
    return null;
  }
}

final walletTypeProvider =
    NotifierProvider<_WalletTypeNotifier, WalletType?>(_WalletTypeNotifier.new);

class _WcSessionNotifier extends Notifier<ReownAppKitModalSession?> {
  @override
  ReownAppKitModalSession? build() {
    ref.keepAlive();
    return null;
  }
}

final wcSessionProvider =
    NotifierProvider<_WcSessionNotifier, ReownAppKitModalSession?>(
        _WcSessionNotifier.new);

class _UserAddressNotifier extends Notifier<EthereumAddress> {
  @override
  EthereumAddress build() {
    ref.keepAlive();
    final session = ref.watch(wcSessionProvider);
    return session != null
        ? EthereumAddress.fromHex(
            session.namespaces!['eip155']!.accounts[0].split(':').last)
        : zeroAddress;
  }
}

final userAddressProvider =
    NotifierProvider<_UserAddressNotifier, EthereumAddress>(
        _UserAddressNotifier.new);
