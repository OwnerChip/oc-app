import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/config/chains.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

// ── Alchemy Smart Wallets endpoint ────────────────────────────────────────────
//
// wallet_prepareCalls and wallet_sendPreparedCalls live at the CHAIN-AGNOSTIC
// Alchemy Smart Wallets gateway, NOT on the chain-specific node URL.
//
//   ✓  https://api.g.alchemy.com/v2/{apiKey}          ← correct
//   ✗  https://polygon-mainnet.g.alchemy.com/v2/{key}  ← was giving "Unsupported method on eth"
//
// The chainId is passed in the request body.

const String _alchemySmartWalletBase = 'https://api.g.alchemy.com/v2/';

// ── Public API ────────────────────────────────────────────────────────────────

/// Applies the EIP-191 "personal_sign" prefix to a 32-byte hash:
///   keccak256("\x19Ethereum Signed Message:\n32" + hashBytes)
///
/// Card-based signers (OwnerCard / CertificateCard) sign raw bytes, so we
/// must manually apply the prefix that software wallets add internally.
Uint8List applyPersonalSignPrefix(Uint8List hashBytes) {
  const prefix = '\x19Ethereum Signed Message:\n32';
  final prefixBytes = Uint8List.fromList(prefix.codeUnits);
  final combined = Uint8List(prefixBytes.length + hashBytes.length)
    ..setRange(0, prefixBytes.length, prefixBytes)
    ..setRange(prefixBytes.length, prefixBytes.length + hashBytes.length,
        hashBytes);
  return keccak256(combined);
}

/// Prepares a gasless UserOperation via Alchemy's `wallet_prepareCalls`.
///
/// Parameters:
///   [chainId]  – target network (e.g. 137 for Polygon)
///   [from]     – **EOA** signer address (your wallet, NOT a smart contract).
///                Alchemy resolves or creates the associated smart wallet
///                (LightAccount) server-side — you do not need to know its
///                address.
///   [to]       – the contract to call
///   [callData] – ABI-encoded function call (raw, not wrapped in execute())
///   [value]    – native value to forward (default "0x0")
///
/// If [ALCHEMY_GAS_POLICY_ID] is set the operation is gas-sponsored via
/// Alchemy Gas Manager.  Without it the smart wallet must hold native token.
///
/// Returns the raw Alchemy result containing:
///   • `type` / `data` / `chainId`      – forwarded to wallet_sendPreparedCalls
///   • `signatureRequest.data.raw`      – the hash the EOA must sign
Future<Map<String, dynamic>> alchemyPrepareCalls({
  required int chainId,
  required EthereumAddress from, // EOA (wallet address)
  required EthereumAddress to,
  required String callData,
  String value = '0x0',
}) async {
  final url = '$_alchemySmartWalletBase${_apiKey(chainId)}';
  final policyId = dotenv.maybeGet('ALCHEMY_GAS_POLICY_ID');
  final hasPolicy = policyId != null && policyId.isNotEmpty;

  final Map<String, dynamic> params = {
    'calls': [
      {'to': to.hexEip55, 'data': callData, 'value': value}
    ],
    'from': from.hexEip55, // EOA: Alchemy creates/uses the smart wallet
    'chainId': '0x${chainId.toRadixString(16)}',
    if (hasPolicy)
      'capabilities': {
        'paymasterService': {'policyId': policyId}
      },
  };

  talker.log('wallet_prepareCalls → $url');
  talker.log('wallet_prepareCalls request params: $params');

  final dio = Dio();
  try {
    final response = await dio.post(url, data: {
      'jsonrpc': '2.0',
      'id': 1,
      'method': 'wallet_prepareCalls',
      'params': [params],
    });

    talker.log('wallet_prepareCalls raw response (${response.statusCode}): ${response.data}');

    if (response.data['error'] != null) {
      final err = response.data['error'];
      talker.error('wallet_prepareCalls JSON-RPC error: $err');
      throw Exception('wallet_prepareCalls error: $err');
    }

    final result = response.data['result'];
    if (result == null) {
      talker.error('wallet_prepareCalls returned null result. Full body: ${response.data}');
      throw Exception('wallet_prepareCalls returned null result');
    }

    talker.log('wallet_prepareCalls result keys: ${(result as Map).keys.toList()}');
    return result as Map<String, dynamic>;
  } on DioException catch (e) {
    final body = e.response?.data;
    talker.error('wallet_prepareCalls HTTP ${e.response?.statusCode}: $body');
    throw Exception(
        'wallet_prepareCalls failed (${e.response?.statusCode}): $body');
  }
}

/// Submits signed prepared call(s) via `wallet_sendPreparedCalls`.
///
/// Handles two shapes returned by `wallet_prepareCalls`:
///
///  • `type: "user-operation-v070"` – single UserOp (normal case after first tx)
///  • `type: "array"` – array of items:
///      - `authorization` (EIP-7702 delegation, first-time only)
///      - `user-operation-v070` (the actual call)
///
/// [preparedResult]   – raw result map from [alchemyPrepareCalls]
/// [userOpSignature]  – personal_sign signature for the user-operation item
/// [authSignature]    – eth_sign (raw) signature for the authorization item.
///                      EIP-7702 auth is verified against the raw hash, so
///                      eth_sign (no EIP-191 prefix) must be used — personal_sign
///                      would produce a mismatched recovered address.
///                      Only needed when result type is "array".
///
/// Returns the UserOperation hash for polling.
Future<String> alchemySendPreparedCalls({
  required int chainId,
  required Map<String, dynamic> preparedResult,
  required String userOpSignature,
  String? authSignature,
}) async {
  final url = '$_alchemySmartWalletBase${_apiKey(chainId)}';
  final resultType = preparedResult['type'] as String? ?? '';

  late Map<String, dynamic> callPayload;

  if (resultType == 'array') {
    final items = (preparedResult['data'] as List).cast<Map<String, dynamic>>();
    final signedItems = items.map<Map<String, dynamic>>((item) {
      final itemType = item['type'] as String? ?? '';
      // Strip signatureRequest – Alchemy doesn't want it back
      final out = Map<String, dynamic>.from(item)..remove('signatureRequest');
      if (itemType == 'authorization') {
        out['signature'] = {
          'type': 'secp256k1',
          'data': authSignature ?? userOpSignature,
        };
      } else {
        // user-operation-v070 (and any future types)
        out['signature'] = {'type': 'secp256k1', 'data': userOpSignature};
      }
      return out;
    }).toList();

    callPayload = {'type': 'array', 'data': signedItems};
    talker.log('wallet_sendPreparedCalls array payload: $callPayload');
  } else {
    // Single user-operation-v070
    callPayload = {
      'type': resultType,
      'data': preparedResult['data'],
      'chainId': preparedResult['chainId'],
      'signature': {'type': 'secp256k1', 'data': userOpSignature},
    };
  }

  final dio = Dio();
  try {
    final response = await dio.post(url, data: {
      'jsonrpc': '2.0',
      'id': 1,
      'method': 'wallet_sendPreparedCalls',
      'params': [callPayload],
    });

    talker.log(
        'wallet_sendPreparedCalls raw response (${response.statusCode}): ${response.data}');

    if (response.data['error'] != null) {
      final err = response.data['error'];
      talker.error('wallet_sendPreparedCalls error: $err');
      throw Exception('wallet_sendPreparedCalls error: $err');
    }

    final result = response.data['result'] as Map<String, dynamic>;
    // userOpHash at result.details.data.hash; fall back to result.id
    final details = result['details'] as Map<String, dynamic>?;
    final data = details?['data'] as Map<String, dynamic>?;
    return (data?['hash'] as String?) ?? (result['id'] as String);
  } on DioException catch (e) {
    final body = e.response?.data;
    talker.error(
        'wallet_sendPreparedCalls HTTP ${e.response?.statusCode}: $body');
    throw Exception(
        'wallet_sendPreparedCalls failed (${e.response?.statusCode}): $body');
  }
}

/// Polls until the UserOperation is mined (up to ~3 min, 60 × 3 s).
///
/// Uses `eth_getUserOperationByHash` (chain-specific RPC) – checks for a
/// non-null `transactionHash` in the result, then verifies execution success
/// via `eth_getUserOperationReceipt`.
Future<String> waitForUserOpReceipt(int chainId, String userOpHash) async {
  final rpcUrl = chainConfig[chainId]!.rpcUrl;
  final dio = Dio();
  const maxAttempts = 60;
  const delay = Duration(seconds: 3);

  for (int attempt = 0; attempt < maxAttempts; attempt++) {
    await Future.delayed(delay);

    try {
      final byHashResp = await dio.post(rpcUrl, data: {
        'id': 1,
        'jsonrpc': '2.0',
        'method': 'eth_getUserOperationByHash',
        'params': [userOpHash],
      });

      if (byHashResp.data['error'] == null) {
        final result = byHashResp.data['result'];
        final txHash = result?['transactionHash'] as String?;
        if (txHash != null && txHash.isNotEmpty) {
          talker.log(
              'UserOp $userOpHash mined in $txHash (attempt ${attempt + 1})');
          // Verify execution success (optional – log reverts, don't block)
          try {
            final receiptResp = await dio.post(rpcUrl, data: {
              'id': 1,
              'jsonrpc': '2.0',
              'method': 'eth_getUserOperationReceipt',
              'params': [userOpHash],
            });
            final receipt = receiptResp.data['result'];
            if (receipt != null && receipt['success'] == false) {
              throw Exception(
                  'UserOperation reverted on-chain (hash: $userOpHash)');
            }
          } catch (e) {
            if (e is Exception &&
                e.toString().contains('UserOperation reverted')) rethrow;
            talker.warning('Receipt check skipped: $e');
          }
          return txHash;
        }
      } else {
        talker.warning(
            'eth_getUserOperationByHash error (attempt ${attempt + 1}): ${byHashResp.data['error']}');
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('UserOperation reverted')) {
        rethrow;
      }
      talker.error('Polling error (attempt ${attempt + 1}): $e');
    }
  }

  throw Exception(
      'UserOperation not confirmed after ${maxAttempts * delay.inSeconds}s '
      '(hash: $userOpHash)');
}

// ── Private helpers ───────────────────────────────────────────────────────────

/// Extracts the Alchemy API key from the chain's rpcUrl.
/// rpcUrl format: "https://<network>.g.alchemy.com/v2/<apiKey>"
String _apiKey(int chainId) {
  final rpcUrl = chainConfig[chainId]!.rpcUrl;
  final parts = rpcUrl.split('/v2/');
  if (parts.length < 2 || parts[1].isEmpty) {
    throw Exception(
        'Cannot extract Alchemy API key from rpcUrl: $rpcUrl');
  }
  return parts[1];
}

