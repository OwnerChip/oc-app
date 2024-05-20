
import 'package:web3auth_flutter/output.dart';

class Web3AuthNotifierData {

  final Web3AuthResponse? web3AuthResponse;

  const Web3AuthNotifierData({
    this.web3AuthResponse,
  });

  factory Web3AuthNotifierData.initial() {
    return const Web3AuthNotifierData(
      web3AuthResponse: null,
    );
  }

  Web3AuthNotifierData copyWith({
    Web3AuthResponse? web3AuthResponse,
  }) {
    return Web3AuthNotifierData(
      web3AuthResponse: web3AuthResponse ?? this.web3AuthResponse,
    );
  }
}