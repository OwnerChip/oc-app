import 'package:web3dart/web3dart.dart';

final EthereumAddress zeroAddress =
    EthereumAddress.fromHex('0x0000000000000000000000000000000000000000');

//mint function signatures
final String mintFunctionSignature = '0xcb5a7173';
final String gaslessMintFunctionSignature = '0x7a7f274d';

//burn function signatures
final String burnFunctionSignature = '0x469fd767';
final String gaslessBurnFunctionSignature = '0xd6fc7cef';
