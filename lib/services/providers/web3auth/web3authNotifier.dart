import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/services/providers/web3auth/web3authNotifierData.dart';
import 'package:web3auth_flutter/output.dart';

class Web3AuthNotifier extends Notifier<Web3AuthNotifierData> {
  @override
  Web3AuthNotifierData build() {
    return Web3AuthNotifierData.initial();
  }

  void setWeb3AuthResponse(Web3AuthResponse? web3AuthResponse) {
    state = state.copyWith(web3AuthResponse: web3AuthResponse);
  }
}

final web3AuthNotifierProvider =
    NotifierProvider<Web3AuthNotifier, Web3AuthNotifierData>(
  Web3AuthNotifier.new,
);
