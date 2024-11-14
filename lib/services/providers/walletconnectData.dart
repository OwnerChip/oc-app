import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:reown_appkit/reown_appkit.dart';

//****WALLETCONNECT****

//wallet connect 2 client provider
final w3mServiceProvider = StateProvider<ReownAppKitModal?>((ref) {
  return null;
});


final walletTypeProvider = StateProvider<WalletType?>((ref) {
  return null;
});

final wcSessionProvider = StateProvider<ReownAppKitModalSession?>((ref) {
  return null;
});

final userAddressProvider = StateProvider<EthereumAddress>((ref) {
  final session = ref.watch(wcSessionProvider);

  final addr = session != null
      ? EthereumAddress.fromHex(
          session.namespaces!['eip155']!.accounts[0].split(':').last)
      : zeroAddress;
  return addr;
});
