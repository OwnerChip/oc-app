import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:web3dart/web3dart.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

//****WALLETCONNECT****

//wallet connect 2 provider
final wcProvider = StateProvider<Web3App?>((ref) {
  return null;
});

final walletTypeProvider = StateProvider<WalletType?>((ref) {
  return null;
});

final wcSessionProvider = StateProvider<SessionData?>((ref) {
  return null;
});

final userAddressProvider = StateProvider<EthereumAddress>((ref) {
  final session = ref.watch(wcSessionProvider);
  final addr = session != null
      ? EthereumAddress.fromHex(
          session.namespaces['eip155']!.accounts[0].split(':').last)
      : zeroAddress;
  return addr;
});
